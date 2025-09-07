class ShortenedUrlsController < ApplicationController
  before_action :set_shortened_url, only: %i[ show edit update destroy ]

  # GET /shortened_urls or /shortened_urls.json
  def index
    @shortened_urls = ShortenedUrl.all
  end

  # GET /shortened_urls/1 or /shortened_urls/1.json
  def show
  end

  # GET /shortened_urls/new
  def new
    @shortened_url = ShortenedUrl.new
  end

  # GET /shortened_urls/1/edit
  def edit
  end

  # POST /shortened_urls or /shortened_urls.json
  def create
    @shortened_url = ShortenUrlService.new.create(shortened_url_params)

    respond_to do |format|
      if @shortened_url.saved?
        format.html { redirect_to @shortened_url.model, notice: "Shortened url was successfully created." }
        format.json { render :show, status: :created, location: @shortened_url.model }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @shortened_url.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /shortened_urls/1 or /shortened_urls/1.json
  def update
    respond_to do |format|
      if @shortened_url.update(shortened_url_params)
        format.html { redirect_to @shortened_url, notice: "Shortened url was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @shortened_url }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @shortened_url.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /shortened_urls/1 or /shortened_urls/1.json
  def destroy
    @shortened_url.destroy!

    respond_to do |format|
      format.html { redirect_to shortened_urls_path, notice: "Shortened url was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_shortened_url
    @shortened_url = ShortenedUrl.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def shortened_url_params
    params.require(:shortened_url).permit(:target, :slug)
  end
end
