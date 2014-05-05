require 'spec_helper'
describe "adding songs" do
  subject { page }

  let!(:root) {FactoryGirl.create(:root)}
  let!(:sub) {FactoryGirl.create(:directory, name: "n", parent: root)}

  describe "GET /songs/new" do
    before do
      SongUploader.enable_processing = true
      SongUploader.any_instance.stub(:convert_to_ogg).and_return(nil)
      SongUploader.any_instance.stub(:convert_to_mp3).and_return(nil)
    end

    after do
      SongUploader.enable_processing = false
      CarrierWave.clean_cached_files!
    end

    shared_examples_for "valid access rights" do
      context "not submiting a song file" do
        before do
          visit new_song_path
          fill_in "Name", with: "pop/yay"
          select "n/", from: "Category"
          click_button "Create Song"
        end

        it_behaves_like "a failed upload"
        it { should have_content "Sound content type is invalid" }

      end

      context "submitting an invalid file type" do
        before do
          visit new_song_path
          fill_in "Name", with: "pop/yay"
          select "n/", from: "Category"
          attach_file "Sound", Rails.root.join('spec', 'fixtures', 'files', 'dangerous_file.exe')
          click_button "Create Song"
        end

        it_behaves_like "a failed upload"
        it { should have_content "Sound content type is invalid" }

      end

      context "submitting the same file again" do
        before do
          same = FactoryGirl.create(:song, directory: root, sound_fingerprint: "fingerprint")
          Digest::MD5.stub(:hexdigest) { "fingerprint" }
          visit new_song_path
          fill_in "Name", with: "pop/yay"
          select "n/", from: "Category"
          attach_file "Sound", Rails.root.join('spec', 'fixtures', 'files', 'test.mp3')
          click_button "Create Song"
          same.destroy
        end

        it_behaves_like "a failed upload"
        it { should have_content "has already been uploaded" }

      end

      context "submiting a valid song file" do
        before do
          visit new_song_path
          fill_in "Name", with: "pop/yay"
          select "n/", from: "Category"
          attach_file "Sound", Rails.root.join('spec', 'fixtures', 'files', 'test.mp3')
          click_button "Create Song"
        end

        it_behaves_like "a successful upload", "n/pop/yay"

      end

    end

    shared_examples_for "a successful upload" do |full_path|
      specify { expect(Song.find_by_full_path full_path).to_not be_nil }
      specify { expect(Directory.find_by_full_path full_path.gsub(%r{/[^/]*$}, '/')).to_not be_nil }
      specify { expect(current_path).to eq song_path(Song.find_by_full_path full_path) }
    end
    shared_examples_for "a failed upload" do
      specify { expect( Song.count ).to eq 0 }
      specify { expect( Directory.count ).to eq 2}
      specify { expect(current_path).to eq new_song_path }
    end

    context "not logged in" do
      before do
        visit new_song_path
      end

      its(:status_code) { should eq 403}
    end

    context "logged in not as unauthorized user" do
      before do
        user = FactoryGirl.create(:user) 
        user.uploader = false
        user.save
        login user
        visit new_song_path
      end
      its(:status_code) { should eq 403}
    end


    context "logged in as uploader" do
      before do
        login FactoryGirl.create(:user)
        visit new_song_path
      end

      it_behaves_like "valid access rights"
    end

    context "logged in as admin" do
      before do
        login FactoryGirl.create(:admin)
        visit new_song_path
      end

      it_behaves_like "valid access rights"
    end


  end
end
