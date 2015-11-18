require 'spec_helper'

module UTF8Cleaner

  describe URIString do
    let(:invalid_string)   { URIString.new('%FF') }
    let(:ascii_string)     { URIString.new('foo') }
    let(:encoded_string)   { URIString.new('%26') }
    let(:multibyte_string) { URIString.new('%E2%9C%93') }
    let(:complex_invalid_string) { URIString.new('foo/%FFbar%2e%2fbaz%26%3B%E2%9C%93%E2%9Cbaz') }
                                                # foo/   bar.  /  baz&  ;  √              baz
    let(:not_even_hex_chars1)  { URIString.new('%x') }
    let(:not_even_hex_chars2)  { URIString.new('%0zhey') }

    describe '#new' do
      it { expect(encoded_string).to be_a(URIString) }
    end

    describe '#cleaned' do
      it { expect(invalid_string.cleaned).to eq('') }
      it { expect(ascii_string.cleaned).to eq('foo') }
      it { expect(encoded_string.cleaned).to eq('%26') }
      it { expect(multibyte_string.cleaned).to eq('%E2%9C%93') }
      it { expect(complex_invalid_string.cleaned).to eq('foo/bar%2e%2fbaz%26%3B%E2%9C%93baz') }
      # it { expect(no_byte_at_all.cleaned).to eq('') }
      it { expect(not_even_hex_chars1.cleaned).to eq('') }
      it { expect(not_even_hex_chars2.cleaned).to eq('hey') }
    end

    describe '#valid?' do
      it { expect(ascii_string).to be_valid }
      it { expect(encoded_string).to be_valid }
      it { expect(multibyte_string).to be_valid }

      it { expect(invalid_string).to_not be_valid }
      it { expect(complex_invalid_string).to_not be_valid }
      it { expect(not_even_hex_chars1).to_not be_valid }
      it { expect(not_even_hex_chars2).to_not be_valid }
    end

  end

end
