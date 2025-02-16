# frozen_string_literal: true

module Setup
  class Concepts
    class_attribute :concepts

    def run
      downloader = Setup::DownloadConcepts.new
      downloader.fetch_concepts
      creator = Setup::CreateConcepts.new(downloader.concepts)
      creator.create_all
    end
  end
end
