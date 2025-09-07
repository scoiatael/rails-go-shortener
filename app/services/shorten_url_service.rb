class ShortenUrlService
  CreateResult = Struct.new(:saved, :model) do
    def to_model
      model
    end

    def errors
      model.errors
    end
  end

  def create(params)
    shortened_url = ShortenedUrl.new(params)
    CreateResult.new(saved: shortened_url.save, model: shortened_url)
  end
end
