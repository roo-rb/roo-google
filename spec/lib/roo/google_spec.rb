require 'spec_helper'

RSpec.describe Roo::Google do
  def key_of(spreadsheetname)
    {
      'write.me' => '0AvDjm7u2fQg_dEZOc0Z0bU1CeWEtYUZOOVdtTkoxaEE',
      'numbers1' => '0AvDjm7u2fQg_dGJLQnhqMUJlYTNzSGh3cF95NWRlQUE',
      'matrix'   => '0AvDjm7u2fQg_dFF0bDVQbXN0dTd5eHpqcG4tckR1M2c'
    }[spreadsheetname]
  end

  let(:access_token) { 'ya29.UAG8d0gmCfJrTzgwQdWTHqG7fDoilKh-aJDSBAmVdre1CDfUHz0ouOwANUVVDnyWVZKSGa_EBUYZqw' }
  let(:key) { '0AvDjm7u2fQg_dGs2Qm5XQno3WDFVUnJsMG5KWXVZZnc' }
  subject { described_class.new(key, access_token: access_token) }

  context '.new' do
    context 'given an access token' do

      subject {
        described_class.new(key, access_token: access_token)
      }

      it 'creates an instance' do
        VCR.use_cassette('google_drive_access_token') do
          expect(subject).to be_a(described_class)
        end
      end
    end
  end

  context '.set' do
    let(:key) { '0AvDjm7u2fQg_dGs2Qm5XQno3WDFVUnJsMG5KWXVZZnc' }

    it 'records the value' do
      VCR.use_cassette('google_drive_set') do
        expect(subject.cell(1, 1)).to eq('1x1')
        expect(subject.cell(1, 2)).to eq('1x2')
        expect(subject.cell(2, 1)).to eq('2x1')
        expect(subject.cell(2, 2)).to eq('2x2')
        subject.set(1, 1, '1x1')
        subject.set(1, 2, '1x2')
        subject.set(2, 1, '2x1')
        subject.set(2, 2, '2x2')
        expect(subject.cell(1, 1)).to eq('1x1')
        expect(subject.cell(1, 2)).to eq('1x2')
        expect(subject.cell(2, 1)).to eq('2x1')
        expect(subject.cell(2, 2)).to eq('2x2')
      end
    end
  end

  context '#date?' do
    {
      'DDMMYYYY' => { format: nil, values: ['21/11/1962', '11/21/1962'] },
      'MMDDYYYY' => { format: '%m/%d/%Y', values: ['11/21/1962', '21/11/1962'] },
      'YYYYMMDD' => { format: '%Y-%m-%d', values: ['1962-11-21', '1962-21-11'] }
    }.each do |title, data|
      context title do
        before :each do
          subject.date_format = data[:format] if data[:format]
        end
        it "should accept #{data[:values][0]}" do
          expect(subject.date?(data[:values][0])).to be_truthy
        end
        it "should not accept #{data[:values][1]}" do
          expect(subject.date?(data[:values][1])).to be_falsey
        end
      end
    end
  end

  context 'numbers1 document' do
    before :all do
      VCR.insert_cassette('google_drive_numbers1')
    end
    let(:key) { key_of('numbers1') }
    it 'check date fields' do
      expect(subject.celltype(5,1)).to eq(:date)
      expect(subject.cell(5,1)).to eq(Date.new(1961, 11, 21))
      expect(subject.cell(5,1).to_s).to eq('1961-11-21')
    end
    it 'check datetime fields' do
      expect(subject.celltype(18,3)).to eq(:datetime)
      expect(subject.cell(18,3)).to eq(DateTime.new(2014, 12, 12, 12, 12, 0))
    end
    it 'check time fields' do
      # 13:46:12
      expect(subject.celltype(18,4)).to eq(:time)
      expect(subject.cell(18,4)).to eq(49572)
    end
    it 'should check float' do
      expect(subject.celltype(2,7)).to eq(:float)
    end
    it 'should check string' do
      expect(subject.celltype(2,6)).to eq(:string)
      expect(subject.cell(2,6)).to eq('test')
    end
    it 'should check formula' do
      expect(subject.celltype(1,'F')).to eq(:formula)
      expect(subject.cell(1,'F')).to eq(20)
      expect(subject.formula(1,'F')).to eq('=SUM(RC[-5]:RC[-1])')
    end
    it 'check empty?' do
      expect(subject.empty?(2,7)).to be_falsey
      expect(subject.empty?(2,6)).to be_falsey
      expect(subject.empty?(18,4)).to be_falsey
      expect(subject.empty?(18,5)).to be_truthy
    end
    after :all do
      VCR.eject_cassette('google_drive_numbers1')
    end
  end
end
