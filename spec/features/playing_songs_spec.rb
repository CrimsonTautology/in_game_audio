require 'spec_helper'
describe "playing a song" do
  subject { page }

  let!(:root) {FactoryGirl.create(:root)}



  describe "GET /songs/play/:id" do
    let!(:sub) {FactoryGirl.create(:directory, name: "foo", parent: root)}
    let!(:song) do
      FactoryGirl.create(:song,
        name: "fatbeats",
        directory: sub,
        title: "Some Fat Beatz",
        album: "Fat Album",
        artist: "Beatmaster",
        duration: 1234.5,
        play_count: 7
      )
    end
    let!(:play_event) {FactoryGirl.create(:play_event, song: song)}

    shared_examples_for "valid access rights" do
      its(:status_code) { should eq 200}
      it { should have_selector "audio#audio_player" }
      it { should have_selector("source[src='#{song.sound.url}']") }
      it { should have_selector("source[src='#{song.sound.ogg.url}']") }
    end

    context "not logged in" do
      before do
        visit play_song_path song
      end

      its(:status_code) { should eq 403}
    end

    context "logged in as uploader" do
      before do
        login FactoryGirl.create(:uploader)
        visit play_song_path song
      end
      its(:status_code) { should eq 403}
    end


    context "logged in as admin" do
      before do
        login FactoryGirl.create(:admin)
        visit play_song_path song
      end

      it_behaves_like "valid access rights"
      it { should have_selector("audio[data-volume='1.0']") }
      it { should have_selector("audio[data-seek='0']") }
    end

    context "with valid play event token" do
      before do
        visit "#{play_song_path(song)}?access_token=#{play_event.access_token}&volume=0.66&seek=75"
      end

      it_behaves_like "valid access rights"
      it { should have_selector("audio[data-volume='0.18975']") }
      it { should have_selector("audio[data-seek='75']") }
    end

    context "with invalid play event token" do
      before do
        play_event.invalidated_at = 1.hour.ago
        play_event.save!
        visit "#{play_song_path(song)}?access_token=#{play_event.access_token}&volume=0.66&seek=75"
      end

      its(:status_code) { should eq 403}
    end

    context "with valid play event token but different song" do
      before do
        play_event.song = FactoryGirl.create(:song, directory: root)
        play_event.save!
        visit "#{play_song_path(song)}?access_token=#{play_event.access_token}&volume=0.66&seek=75"
      end

      its(:status_code) { should eq 403}
    end
  end
end
