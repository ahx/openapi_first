class AttachmentsController < ApplicationController
  def show
    send_file Rails.root.join('storage', 'example.png')
  end
end
