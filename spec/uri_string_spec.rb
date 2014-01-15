# -*- encoding: utf-8 -*-

require 'spec_helper'

module UTF8Cleaner

  describe URIString do
    let(:empty_string)   { URIString.new('') }
    let(:invalid_string)   { URIString.new('%FF') }
    let(:ascii_string)     { URIString.new('foo') }
    let(:encoded_string)   { URIString.new('%26') }
    let(:multibyte_string) { URIString.new('%E2%9C%93') }
    let(:complex_invalid_string) { URIString.new('foo/%FFbar%2e%2fbaz%26%3B%E2%9C%93%E2%9Cbaz') }
                                                # foo/   bar.  /  baz&  ;  √              baz
    let(:not_encoded_invalid_string) { URIString.new('a??a�E�La??-a?��e3�300ao?-a/?a??a??ao��a?/1-8-1-15-1-17-a�C?a?/e��2a??e2�Ea�C�e�?a�C�-2') }

    describe '#new' do
      it { encoded_string.should be_a URIString }
    end

    describe '#cleaned' do
      it { invalid_string.cleaned.should eq('') }
      it { ascii_string.cleaned.should eq('foo') }
      it { encoded_string.cleaned.should eq('%26') }
      it { multibyte_string.cleaned.should eq('%E2%9C%93') }
      it { complex_invalid_string.cleaned.should eq('foo/bar%2e%2fbaz%26%3B%E2%9C%93baz') }
    end

    describe '#encoded?' do
      it { encoded_string.should be_encoded }
      it { invalid_string.should be_encoded }
      it { multibyte_string.should be_encoded }
      it { complex_invalid_string.should be_encoded }

      it { ascii_string.should_not be_encoded }
    end

    describe '#valid?' do
      it { empty_string.should be_valid }
      it { ascii_string.should be_valid }
      it { encoded_string.should be_valid }
      it { multibyte_string.should be_valid }

      it { invalid_string.should_not be_valid }
      it { complex_invalid_string.should_not be_valid }
      it { not_encoded_invalid_string.should_not be_valid }
    end

  end

end
