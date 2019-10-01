require 'spec_helper'

RSpec.describe ActiveTracker::Model do
  context 'loading an item' do
    before do
      @key = '/ActiveTracker/Request/20190927194300/id:e52c5517-eb46-4ba5-be56-90aa7436f26a/path:%2Flogin%3Ffoo/method:get/summary'
      @value = {"items": [1,2,3]}.to_json
      @obj = ActiveTracker::Model.new(@key, @value)
    end

    it 'sets the id' do
      expect(@obj.id).to eq(@key)
    end

    it 'sets the type' do
      expect(@obj.type).to eq("Request")
    end

    it 'sets the data_type' do
      expect(@obj.data_type).to eq("summary")
    end

    it 'sets the tags' do
      expect(@obj.tags).to eq({id: "e52c5517-eb46-4ba5-be56-90aa7436f26a", method: "get", path: "/login?foo"})
    end

    it 'sets the log_at' do
      Timecop.freeze(Time.new(2019, 9, 1, 11, 00)) do
        @obj = ActiveTracker::Model.new(@key, @value)
        expect(@obj.log_at).to eq(Time.new(2019, 9, 27, 19, 43, 00))
      end
    end

    it 'sets the values from the body' do
      expect(@obj.items).to eq([1,2,3])
    end
  end
end
