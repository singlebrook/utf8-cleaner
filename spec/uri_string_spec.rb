# frozen_string_literal: true

require 'spec_helper'

module UTF8Cleaner
  describe URIString do
    let(:invalid_string)   { described_class.new('%FF') }
    let(:ascii_string)     { described_class.new('foo') }
    let(:encoded_string)   { described_class.new('%26') }
    let(:multibyte_string) { described_class.new('%E2%9C%93') }
    let(:complex_invalid_string) do
      # ------------ foo/   bar.  /  baz&  ;  √              baz
      described_class.new('foo/%FFbar%2e%2fbaz%26%3B%E2%9C%93%E2%9Cbaz')
    end
    let(:no_byte_at_all)      { described_class.new('%') }
    let(:not_even_hex_chars1) { described_class.new('%x') }
    let(:not_even_hex_chars2) { described_class.new('%0zhey') }
    let(:mixed_encodings)     { described_class.new('§%e2') }

    describe '#new' do
      it { expect(encoded_string).to be_a(described_class) }
    end

    describe '#cleaned' do
      it { expect(invalid_string.cleaned).to eq('') }
      it { expect(ascii_string.cleaned).to eq('foo') }
      it { expect(encoded_string.cleaned).to eq('%26') }
      it { expect(multibyte_string.cleaned).to eq('%E2%9C%93') }
      it { expect(complex_invalid_string.cleaned).to eq('foo/bar%2e%2fbaz%26%3B%E2%9C%93baz') }
      it { expect(no_byte_at_all.cleaned).to eq('') }
      it { expect(not_even_hex_chars1.cleaned).to eq('') }
      it { expect(not_even_hex_chars2.cleaned).to eq('hey') }
      it { expect(mixed_encodings.cleaned).to eq('§') }
    end

    describe '#valid?' do
      it { expect(ascii_string).to be_valid }
      it { expect(encoded_string).to be_valid }
      it { expect(multibyte_string).to be_valid }
      it { expect(invalid_string).not_to be_valid }
      it { expect(complex_invalid_string).not_to be_valid }
      it { expect(no_byte_at_all).not_to be_valid }
      it { expect(not_even_hex_chars1).not_to be_valid }
      it { expect(not_even_hex_chars2).not_to be_valid }
      it { expect(mixed_encodings).not_to be_valid }
    end
  end
end
