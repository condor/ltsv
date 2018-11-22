require 'spec_helper'

RSpec.describe LTSV do

  describe :parse do
    context 'String argument' do
      it 'can parse labeled tab separated values into a hash in an array' do
        line = "label1:value1\tlabel2:value2"
        expect(LTSV.parse(line)).to eq [{:label1 => 'value1', :label2 => 'value2'}]
      end

      it 'can parse multiline labeled tab separated values into hashes in an array' do
        line = "label1:value1\tlabel2:value2\nlabel1:value3\tlabel2:value4"
        expect(LTSV.parse(line)).to eq [
                                         {:label1 => 'value1', :label2 => 'value2'},
                                         {:label1 => 'value3', :label2 => 'value4'}
                                       ]
      end

      it 'can parse the value that contains escape sequences' do

        expect(LTSV.parse("label1:value1\tlabel2:value\\nvalue")).to \
          eq [{:label1 => 'value1', :label2 => "value\nvalue"}]

        expect(LTSV.parse("label1:value1\tlabel2:value\\rvalue")).to \
          eq [{:label1 => 'value1', :label2 => "value\rvalue"}]

        expect(LTSV.parse("label1:value1\tlabel2:value\\tvalue")).to \
          eq [{:label1 => 'value1', :label2 => "value\tvalue"}]

        expect(LTSV.parse("label1:value1\tlabel2:value\\\\value")).to \
          eq [{:label1 => 'value1', :label2 => "value\\value"}]
      end

      it 'parses the value as-is when the backslash with a following ordinal character' do

        expect(LTSV.parse("label1:value1\tlabel2:value\\avalue")).to \
          eq [{:label1 => 'value1', :label2 => "value\\avalue"}]
      end

      it 'parses the empty value field as nil' do
        expect(LTSV.parse("label1:\tlabel2:value2")).to \
          eq [{:label1 => nil, :label2 => 'value2'}]
      end
    end

    context 'IO argment' do
      it 'can parse labeled tab separated values into file' do
        expect(LTSV.parse(File.open("#{File.dirname(__FILE__)}/test.ltsv"))).to \
          eq [
            {:label1 => 'value1', :label2 => 'value\\nvalue'},
            {:label3 => 'value3', :label4 => 'value\\rvalue'},
            {:label5 => 'value5', :label6 => 'value\\tvalue'},
            {:label7 => 'value7', :label8 => 'value\\\\value'},
            {:label9 => 'value9', :label10 => nil, :label11 => 'value11'}
          ]
      end
    end
  end

  describe :load do
    specify 'can load labeled tab separated values from file' do
      stream = File.open("#{File.dirname(__FILE__)}/test.ltsv")
      expect(LTSV.load(stream)).to \
        eq [
          {:label1 => 'value1', :label2 => 'value\\nvalue'},
          {:label3 => 'value3', :label4 => 'value\\rvalue'},
          {:label5 => 'value5', :label6 => 'value\\tvalue'},
          {:label7 => 'value7', :label8 => 'value\\\\value'},
          {:label9 => 'value9', :label10 => nil, :label11 => 'value11'}
        ]
    end
  end

  describe :dump do

    specify 'dump into the format "label1:value1\tlabel2:value2"' do
      expect(LTSV.dump({:label1 => "value1", :label2 => "value2"})).to \
        eq "label1:value1\tlabel2:value2"
    end

    specify 'CRs, LFs, TABs, and backslashes in the value should be escaped' do
      expect(LTSV.dump({:label1 => "value\rvalue"})).to eq "label1:value\\rvalue"
      expect(LTSV.dump({:label1 => "value\nvalue"})).to eq "label1:value\\nvalue"
      expect(LTSV.dump({:label1 => "value\tvalue"})).to eq "label1:value\\tvalue"
      expect(LTSV.dump({:label1 => "value\\value"})).to eq "label1:value\\value"
    end

    specify ':s in the value should not be escaped' do
      expect(LTSV.dump({:label1 => "value:value"})).to eq "label1:value:value"
    end

    specify 'should not fail when object to dump responds to :to_hash' do
      target = Object.new
      target.instance_eval do
        def to_hash
          {:label => 'value'}
        end
      end
      expect(LTSV.dump(target)).to eq "label:value"
    end

    specify 'should not fail when object to dump responds to :to_h' do
      target = Object.new
      target.instance_eval do
        def to_h
          {:label => 'value'}
        end
      end
      expect(LTSV.dump(target)).to eq "label:value"
    end

    specify 'fails when object to dump does not respond to :to_hash' do
      expect(lambda{LTSV.dump(Object.new)}).to raise_exception(ArgumentError)
    end

    specify 'breaking change: LTSV.dump(nil) should return the empty string' do
      expect(LTSV.dump(nil)).to eq ''
    end

    context 'when given Hash includes a value that returns a frozen String' do
      let(:hash) do
        { label: double(to_s: "value".freeze) }
      end

      it 'does not fail' do
        expect(LTSV.dump(hash)).to eq 'label:value'
      end
    end
  end
end
