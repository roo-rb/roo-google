require 'test_helper'

class TestRooGoogle < MiniTest::Test
  def test_simple_google
    go = Roo::Google.new("egal")
    assert_equal "42", go.cell(1,1)
  end

  def test_formula_google
    with_each_spreadsheet('formula') do |oo|
      oo.default_sheet = oo.sheets.first
      assert_equal 1, oo.cell('A',1)
      assert_equal 2, oo.cell('A',2)
      assert_equal 3, oo.cell('A',3)
      assert_equal 4, oo.cell('A',4)
      assert_equal 5, oo.cell('A',5)
      assert_equal 6, oo.cell('A',6)
      # assert_equal 21, oo.cell('A',7)
      assert_equal 21.0, oo.cell('A',7) #TODO: better solution Fixnum/Float
      assert_equal :formula, oo.celltype('A',7)
      # assert_equal "=[Sheet2.A1]", oo.formula('C',7)
      # !!! different from formulas in OpenOffice
      #was: assert_equal "=sheet2!R[-6]C[-2]", oo.formula('C',7)
      # has Google changed their format of formulas/references to other sheets?
      assert_equal "=Sheet2!R[-6]C[-2]", oo.formula('C',7)
      assert_nil oo.formula('A',6)
      # assert_equal [[7, 1, "=SUM([.A1:.A6])"],
      #   [7, 2, "=SUM([.$A$1:.B6])"],
      #   [7, 3, "=[Sheet2.A1]"],
      #   [8, 2, "=SUM([.$A$1:.B7])"],
      # ], oo.formulas(oo.sheets.first)
      # different format than in openoffice spreadsheets:
      #was:
      # assert_equal [[7, 1, "=SUM(R[-6]C[0]:R[-1]C[0])"],
      #  [7, 2, "=SUM(R1C1:R[-1]C[0])"],
      #  [7, 3, "=sheet2!R[-6]C[-2]"],
      #  [8, 2, "=SUM(R1C1:R[-1]C[0])"]],
      #  oo.formulas(oo.sheets.first)
      assert_equal [[7, 1, "=SUM(R[-6]C:R[-1]C)"],
        [7, 2, "=SUM(R1C1:R[-1]C)"],
        [7, 3, "=Sheet2!R[-6]C[-2]"],
        [8, 2, "=SUM(R1C1:R[-1]C)"]],
        oo.formulas(oo.sheets.first)
    end
  end

  def test_write_google
    # write.me: http://spreadsheets.google.com/ccc?key=ptu6bbahNZpY0N0RrxQbWdw&hl=en_GB
    with_each_spreadsheet('write.me') do |oo|
      oo.default_sheet = oo.sheets.first
      oo.set(1,1,"hello from the tests")
      assert_equal "hello from the tests", oo.cell(1,1)
      oo.set(1,1, 1.0)
      assert_equal 1.0, oo.cell(1,1)
    end
  end

  def test_bug_set_with_more_than_one_sheet_google
    # write.me: http://spreadsheets.google.com/ccc?key=ptu6bbahNZpY0N0RrxQbWdw&hl=en_GB
    with_each_spreadsheet('write.me') do |oo|
      content1 = 'AAA'
      content2 = 'BBB'
      oo.default_sheet = oo.sheets.first
      oo.set(1,1,content1)
      oo.default_sheet = oo.sheets[1]
      oo.set(1,1,content2) # in the second sheet
      oo.default_sheet = oo.sheets.first
      assert_equal content1, oo.cell(1,1)
      oo.default_sheet = oo.sheets[1]
      assert_equal content2, oo.cell(1,1)
    end
  end

  def test_set_with_sheet_argument_google
    with_each_spreadsheet('write.me') do |oo|
      random_row = rand(10)+1
      random_column = rand(10)+1
      content1 = 'ABC'
      content2 = 'DEF'
      oo.set(random_row,random_column,content1,oo.sheets.first)
      oo.set(random_row,random_column,content2,oo.sheets[1])
      assert_equal content1, oo.cell(random_row,random_column,oo.sheets.first)
      assert_equal content2, oo.cell(random_row,random_column,oo.sheets[1])
    end
  end

  def test_set_for_non_existing_sheet_google
    with_each_spreadsheet('ptu6bbahNZpY0N0RrxQbWdw') do |oo|
      assert_raises(RangeError) { oo.set(1,1,"dummy","no_sheet")   }
    end
  end

  require 'matrix'
  def test_matrix
    with_each_spreadsheet('matrix') do |oo|
      oo.default_sheet = oo.sheets.first
      assert_equal Matrix[
        [1.0, 2.0, 3.0],
        [4.0, 5.0, 6.0],
        [7.0, 8.0, 9.0] ], oo.to_matrix
    end
  end

  def test_matrix_selected_range
    with_each_spreadsheet('matrix') do |oo|
      oo.default_sheet = 'Sheet2'
      assert_equal Matrix[
        [1.0, 2.0, 3.0],
        [4.0, 5.0, 6.0],
        [7.0, 8.0, 9.0] ], oo.to_matrix(3,4,5,6)
    end
  end

  def test_matrix_all_nil
    with_each_spreadsheet('matrix') do |oo|
      oo.default_sheet = 'Sheet2'
      assert_equal Matrix[
        [nil, nil, nil],
        [nil, nil, nil],
        [nil, nil, nil] ], oo.to_matrix(10,10,12,12)
    end
  end

  def test_matrix_values_and_nil
    with_each_spreadsheet('matrix') do |oo|
      oo.default_sheet = 'Sheet3'
      assert_equal Matrix[
        [1.0, nil, 3.0],
        [4.0, 5.0, 6.0],
        [7.0, 8.0, nil] ], oo.to_matrix(1,1,3,3)
    end
  end

  def test_matrix_specifying_sheet
    with_each_spreadsheet('matrix') do |oo|
      oo.default_sheet = oo.sheets.first
      assert_equal Matrix[
        [1.0, nil, 3.0],
        [4.0, 5.0, 6.0],
        [7.0, 8.0, nil] ], oo.to_matrix(nil, nil, nil, nil, 'Sheet3')
    end
  end

  # #formulas of an empty sheet should return an empty array and not result in
  # an error message
  # 2011-06-24
  def test_bug_formulas_empty_sheet
    with_each_spreadsheet('emptysheets') do |oo|
      assert_nothing_raised(NoMethodError) {
        oo.default_sheet = oo.sheets.first
        oo.formulas
      }
      assert_equal([], oo.formulas)
    end
  end

  # #to_yaml of an empty sheet should return an empty string and not result in
  # an error message
  # 2011-06-24
  def test_bug_to_yaml_empty_sheet
    with_each_spreadsheet('emptysheets') do |oo|
      assert_nothing_raised(NoMethodError) {
        oo.default_sheet = oo.sheets.first
        oo.to_yaml
      }
      assert_equal('', oo.to_yaml)
    end
  end

  # #to_matrix of an empty sheet should return an empty matrix and not result in
  # an error message
  # 2011-06-25
  def test_bug_to_matrix_empty_sheet
    with_each_spreadsheet('emptysheets') do |oo|
      assert_nothing_raised(NoMethodError) {
        oo.default_sheet = oo.sheets.first
        oo.to_matrix
      }
      assert_equal(Matrix.empty(0,0), oo.to_matrix)
    end
  end

  # 2011-08-03
  def test_bug_datetime_to_csv
    with_each_spreadsheet('datetime') do |oo|
      Dir.mktmpdir do |tempdir|
        datetime_csv_file = File.join(tempdir,"datetime.csv")

        assert oo.to_csv(datetime_csv_file)
        assert File.exists?(datetime_csv_file)
        assert_equal "", file_diff('test/files/so_datetime.csv', datetime_csv_file)
      end
    end
  end

  # Using Date.strptime so check that it's using the method
  # with the value set in date_format
  def test_date
    with_each_spreadsheet('numbers1') do |oo|
      # should default to  DDMMYYYY
      assert oo.date?("21/11/1962")
      assert !oo.date?("11/21/1962")
      oo.date_format = '%m/%d/%Y'
      assert !oo.date?("21/11/1962")
      assert oo.date?("11/21/1962")
      oo.date_format = '%Y-%m-%d'
      assert(oo.date?("1962-11-21"))
      assert(!oo.date?("1962-21-11"))
    end
  end


  def test_sheets
    with_each_spreadsheet('numbers1') do |oo|
      assert_equal ["Tabelle1","Name of Sheet 2","Sheet3","Sheet4","Sheet5"], oo.sheets
      assert_raises(RangeError) { oo.default_sheet = "no_sheet" }
      assert_raises(TypeError)  { oo.default_sheet = [1,2,3] }
      oo.sheets.each { |sh|
        oo.default_sheet = sh
        assert_equal sh, oo.default_sheet
      }
    end
  end

  def test_cells
    with_each_spreadsheet('numbers1') do |oo|
      # warum ist Auswaehlen erstes sheet hier nicht
      # mehr drin?
      oo.default_sheet = oo.sheets.first
      assert_equal 1, oo.cell(1,1)
      assert_equal 2, oo.cell(1,2)
      assert_equal 3, oo.cell(1,3)
      assert_equal 4, oo.cell(1,4)
      assert_equal 5, oo.cell(2,1)
      assert_equal 6, oo.cell(2,2)
      assert_equal 7, oo.cell(2,3)
      assert_equal 8, oo.cell(2,4)
      assert_equal 9, oo.cell(2,5)
      assert_equal "test", oo.cell(2,6)
      assert_equal :string, oo.celltype(2,6)
      assert_equal 11, oo.cell(2,7)
      unless oo.kind_of? Roo::CSV
        assert_equal :float, oo.celltype(2,7)
      end
      assert_equal 10, oo.cell(4,1)
      assert_equal 11, oo.cell(4,2)
      assert_equal 12, oo.cell(4,3)
      assert_equal 13, oo.cell(4,4)
      assert_equal 14, oo.cell(4,5)
      assert_equal 10, oo.cell(4,'A')
      assert_equal 11, oo.cell(4,'B')
      assert_equal 12, oo.cell(4,'C')
      assert_equal 13, oo.cell(4,'D')
      assert_equal 14, oo.cell(4,'E')
      unless oo.kind_of? Roo::CSV
        assert_equal :date, oo.celltype(5,1)
        assert_equal Date.new(1961,11,21), oo.cell(5,1)
        assert_equal "1961-11-21", oo.cell(5,1).to_s
      end
    end
  end

  def test_celltype
    with_each_spreadsheet('numbers1') do |oo|
      assert_equal :string, oo.celltype(2,6)
    end
  end

  def test_cell_address
    with_each_spreadsheet('numbers1') do |oo|
      assert_equal "tata", oo.cell(6,1)
      assert_equal "tata", oo.cell(6,'A')
      assert_equal "tata", oo.cell('A',6)
      assert_equal "tata", oo.cell(6,'a')
      assert_equal "tata", oo.cell('a',6)
      assert_raises(ArgumentError) { assert_equal "tata", oo.cell('a','f') }
      assert_raises(ArgumentError) { assert_equal "tata", oo.cell('f','a') }
      assert_equal "thisisc8", oo.cell(8,3)
      assert_equal "thisisc8", oo.cell(8,'C')
      assert_equal "thisisc8", oo.cell('C',8)
      assert_equal "thisisc8", oo.cell(8,'c')
      assert_equal "thisisc8", oo.cell('c',8)
      assert_equal "thisisd9", oo.cell('d',9)
      assert_equal "thisisa11", oo.cell('a',11)
    end
  end

  def test_sheetname
    with_each_spreadsheet('numbers1') do |oo|
      oo.default_sheet = "Name of Sheet 2"
      assert_equal 'I am sheet 2', oo.cell('C',5)
      assert_raises(RangeError) { oo.default_sheet = "non existing sheet name" }
      assert_raises(RangeError) { oo.default_sheet = "non existing sheet name" }
      assert_raises(RangeError) { oo.cell('C',5,"non existing sheet name")}
      assert_raises(RangeError) { oo.celltype('C',5,"non existing sheet name")}
      assert_raises(RangeError) { oo.empty?('C',5,"non existing sheet name")}
      assert_raises(RangeError) { oo.formula?('C',5,"non existing sheet name")}
      assert_raises(RangeError) { oo.formula('C',5,"non existing sheet name")}
      assert_raises(RangeError) { oo.set('C',5,42,"non existing sheet name")}
      assert_raises(RangeError) { oo.formulas("non existing sheet name")}
      assert_raises(RangeError) { oo.to_yaml({},1,1,1,1,"non existing sheet name")}
    end
  end

  def test_argument_error
    with_each_spreadsheet('numbers1') do |oo|
      assert_nothing_raised(ArgumentError) {  oo.default_sheet = "Tabelle1" }
    end
  end

  def test_bug_italo_ve
    with_each_spreadsheet('numbers1') do |oo|
      oo.default_sheet = "Sheet5"
      assert_equal 1, oo.cell('A',1)
      assert_equal 5, oo.cell('b',1)
      assert_equal 5, oo.cell('c',1)
      assert_equal 2, oo.cell('a',2)
      assert_equal 3, oo.cell('a',3)
    end
  end

  def test_borders_sheets
    with_each_spreadsheet('borders') do |oo|
      oo.default_sheet = oo.sheets[1]
      assert_equal 6, oo.first_row
      assert_equal 11, oo.last_row
      assert_equal 4, oo.first_column
      assert_equal 8, oo.last_column

      oo.default_sheet = oo.sheets.first
      assert_equal 5, oo.first_row
      assert_equal 10, oo.last_row
      assert_equal 3, oo.first_column
      assert_equal 7, oo.last_column

      oo.default_sheet = oo.sheets[2]
      assert_equal 7, oo.first_row
      assert_equal 12, oo.last_row
      assert_equal 5, oo.first_column
      assert_equal 9, oo.last_column
    end
  end

  def test_only_one_sheet
    with_each_spreadsheet('only_one_sheet') do |oo|
      assert_equal 42, oo.cell('B',4)
      assert_equal 43, oo.cell('C',4)
      assert_equal 44, oo.cell('D',4)
      oo.default_sheet = oo.sheets.first
      assert_equal 42, oo.cell('B',4)
      assert_equal 43, oo.cell('C',4)
      assert_equal 44, oo.cell('D',4)
    end
  end

  def test_should_raise_file_not_found_error
    assert_raises(Net::HTTPServerException) {
      Roo::Google.new(key_of('testnichtvorhanden'+'Bibelbund.ods'))
      Roo::Google.new('testnichtvorhanden')
    }
  end
end
