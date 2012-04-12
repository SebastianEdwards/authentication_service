module HATEOAS
  def initialize
    super
    @success_code = 200
    @headers = {'Content-Type' => 'application/vnd.collection+json'}
    @links = []
  end

  def add_header(key, value)
    @headers.merge!({key => value})
  end

  def success_code(code)
    @success_code = code
  end

  def add_link(rel, href, opts = {})
    href = ENV['ROOT_URI'] + href
    @links << opts.merge({rel: rel, href: href})
  end

  def generate_response(data = {})
    content = Content.new(data, @links)
    [@success_code, @headers, content.to_json]
  end

  class Content
    def initialize(content, links)
      @content = content
      @links = links
    end

    def content
      @content.respond_to?(:merge) ? @content : {items: @content}
    end

    def to_json
      {collection: content.merge({links: @links})}.to_json
    end
  end
end
