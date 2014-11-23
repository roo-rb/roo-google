require 'roo/base'
require 'google_drive'

class Roo::Google < Roo::Base
  attr_accessor :date_format, :datetime_format
  # returns an array of sheet names in the spreadsheet
  attr_reader :sheets
  DATE_FORMAT = '%d/%m/%Y'.freeze
  DATE_TIME_FORMAT = '%d/%m/%Y %H:%M:%S'.freeze
  TIME_FORMAT = '%H:%M:%S'.freeze

  # Creates a new Google Drive object.
  def initialize(spreadsheet_key, options = {})
    @filename = spreadsheet_key
    @user = options[:user] || ENV['GOOGLE_MAIL']
    @password = options[:password] || ENV['GOOGLE_PASSWORD']
    @access_token = options[:access_token] || ENV['GOOGLE_TOKEN']
    super
    @cell = Hash.new { |h, k| h[k] = Hash.new }
    @cell_type = Hash.new { |h, k| h[k] = Hash.new }
    @formula = {}
  end

  def worksheets
    @worksheets ||= session.spreadsheet_by_key(@filename).worksheets
  end

  def sheets
    @sheets ||= worksheets.map(&:title)
  end

  def default_sheet
    @default_sheet ||= sheets.first
  end

  %w(date time datetime).each do |key|
    class_eval <<-EOS, __FILE__, __LINE__ + 1
      def #{key}?(string)
        Date.strptime(string, #{key.upcase}_FORMAT)
        true
      rescue
        false
      end
    EOS
  end

  def numeric?(string)
    string =~ /\A[0-9]+[\.]*[0-9]*\z/
  end

  def timestring_to_seconds(value)
    hms = value.split(':')
    hms[0].to_i * 3600 + hms[1].to_i * 60 + hms[2].to_i
  end

  # Returns the content of a spreadsheet-cell.
  # (1,1) is the upper left corner.
  # (1,1), (1,'A'), ('A',1), ('a',1) all refers to the
  # cell at the first line and first row.
  def cell(row, col, sheet = default_sheet)
    validate_sheet!(sheet) # TODO: 2007-12-16
    read_cells(sheet)
    row, col = normalize(row, col)
    value = @cell[sheet]["#{row},#{col}"]
    if celltype(row, col, sheet) == :date
      begin
        return  Date.strptime(value, @date_format)
      rescue ArgumentError
        raise "Invalid Date #{sheet}[#{row},#{col}] #{value} using format '{@date_format}'"
      end
    elsif celltype(row, col, sheet) == :datetime
      begin
        return  DateTime.strptime(value, @datetime_format)
      rescue ArgumentError
        raise "Invalid DateTime #{sheet}[#{row},#{col}] #{value} using format '{@datetime_format}'"
      end
    end
    value
  end

  # returns the type of a cell:
  # * :float
  # * :string
  # * :date
  # * :percentage
  # * :formula
  # * :time
  # * :datetime
  def celltype(row, col, sheet = default_sheet)
    read_cells(sheet)
    row, col = normalize(row, col)
    if @formula.size > 0 && @formula[sheet]["#{row},#{col}"]
      :formula
    else
      @cell_type[sheet]["#{row},#{col}"]
    end
  end

  # Returns the formula at (row,col).
  # Returns nil if there is no formula.
  # The method #formula? checks if there is a formula.
  def formula(row, col, sheet = default_sheet)
    read_cells(sheet)
    row, col = normalize(row, col)
    @formula[sheet]["#{row},#{col}"] && @formula[sheet]["#{row},#{col}"]
  end
  alias_method :formula?, :formula

  # true, if the cell is empty
  def empty?(row, col, sheet = nil)
    value = cell(row, col, sheet)
    return true unless value
    return false if value.class == Date # a date is never empty
    return false if value.class == Float
    return false if celltype(row, col, sheet) == :time
    value.empty?
  end

  # sets the cell to the content of 'value'
  # a formula can be set in the form of '=SUM(...)'
  def set(row, col, value, sheet = default_sheet)
    validate_sheet!(sheet)

    sheet_no = sheets.index(sheet) + 1
    row, col = normalize(row, col)
    add_to_cell_roo(row, col, value, sheet_no)
    # re-read the portion of the document that has changed
    if @cells_read[sheet]
      value, value_type = determine_datatype(value.to_s)

      _set_value(row, col, value, sheet)
      set_type(row, col, value_type, sheet)
    end
  end

  # *DEPRECATED*: Use Roo::Google#set instead
  def set_value(row, col, value, sheet = nil)
    warn '[DEPRECATION] `set_value` is deprecated.  Please use `set` instead.'
    set(row, col, value, sheet)
  end

  %w(first_row last_row first_column last_column).each do |key|
    class_eval <<-EOS, __FILE__, __LINE__ + 1
      def #{key}(sheet = default_sheet)
        unless @#{key}[sheet]
          set_first_last_row_column(sheet)
        end
        @#{key}[sheet]
      end
    EOS
  end

  private

  def set_first_last_row_column(sheet)
    sheet_no = sheets.index(sheet) + 1
    @first_row[sheet], @last_row[sheet], @first_column[sheet], @last_column[sheet] =
       rows_and_cols_min_max(sheet_no)
  end

  def _set_value(row, col, value, sheet = default_sheet)
    @cell[sheet]["#{row},#{col}"] = value
  end

  def set_type(row, col, type, sheet = default_sheet)
    @cell_type[sheet]["#{row},#{col}"] = type
  end

  # read all cells in a sheet.
  def read_cells(sheet = default_sheet)
    validate_sheet!(sheet)
    return if @cells_read[sheet]

    sheet_no = sheets.index(sheet)
    ws = worksheets[sheet_no]
    for row in 1..ws.num_rows
      for col in 1..ws.num_cols
        key = "#{row},#{col}"
        string_value = ws.input_value(row, col) # item['inputvalue'] ||  item['inputValue']
        numeric_value = ws[row, col] # item['numericvalue']  ||  item['numericValue']
        (value, value_type) = determine_datatype(string_value, numeric_value)
        @cell[sheet][key] = value unless value == '' || value.nil?
        @cell_type[sheet][key] = value_type
        @formula[sheet] = {} unless @formula[sheet]
        @formula[sheet][key] = string_value if value_type == :formula
      end
    end
    @cells_read[sheet] = true
  end

  def determine_datatype(val, numval = nil)
    if val.nil? || val[0, 1] == '='
      ty = :formula
      if numeric?(numval)
        val = numval.to_f
      else
        val = numval
      end
    else
      if datetime?(val)
        ty = :datetime
      elsif date?(val)
        ty = :date
      elsif numeric?(val)
        ty = :float
        val = val.to_f
      elsif time?(val)
        ty = :time
        val = timestring_to_seconds(val)
      else
        ty = :string
      end
    end
    [val, ty]
  end

  def add_to_cell_roo(row, col, value, sheet_no = 1)
    sheet_no -= 1
    worksheets[sheet_no][row, col] = value
    worksheets[sheet_no].save
  end

  def entry_roo(value, row, col)
    [value, row, col]
  end

  def rows_and_cols_min_max(sheet_no)
    ws = worksheets[sheet_no - 1]
    rows = []
    cols = []
    for row in 1..ws.num_rows
      for col in 1..ws.num_cols
        if ws[row, col] && !ws[row, col].empty?
          rows << row
          cols << col
        end
      end
    end
    [rows.min, rows.max, cols.min, cols.max]
  end

  def reinitialize
    initialize(@filename, user: @user, password: @password, access_token: @access_token)
  end

  def session
    @session ||= if @user && @password
                   ::GoogleDrive.login(@user, @password)
                 elsif @access_token
                   ::GoogleDrive.login_with_oauth(@access_token)
                 else
                   warn 'set user and password or access token'
                 end
  end
end
