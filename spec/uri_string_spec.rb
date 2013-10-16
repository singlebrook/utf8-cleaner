require 'spec_helper'

module UTF8Cleaner

  describe URIString do
    let(:invalid_string) { URIString.new('%FF') }
    let(:ascii_string)   { URIString.new('foo') }
    let(:encoded_string) { URIString.new('%26') }

    describe '#new' do
      it { encoded_string.should be_a URIString }
    end

    describe '#encoded?' do
      it { encoded_string.should be_encoded }
      it { invalid_string.should be_encoded }

      it { ascii_string.should_not be_encoded }
    end

    describe '#valid?' do
      it { ascii_string.should be_valid }
      it { encoded_string.should be_valid }

      it { invalid_string.should_not be_valid }
    end
  end

end