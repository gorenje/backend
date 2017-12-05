module ImageServer
  module ViewHelpers
    def current_page(page)
      request.path_info.start_with?("/#{page}")
    end
  end
end
