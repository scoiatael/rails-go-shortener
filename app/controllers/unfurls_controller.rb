class UnfurlsController < ApplicationController
  def show
    @shortened_url = ShortenedUrl.find_by(slug: params.require(:slug))

    respond_to do |format|
      format.html { redirect_to @shortened_url.target, allow_other_host: true }
      format.json { render }
    end
  end

  def search
    @shortened_urls = ShortenedUrl.where(slug: params.require(:slug))
  end
end
