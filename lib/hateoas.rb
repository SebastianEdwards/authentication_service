module HATEOAS
  attr_reader :links, :items

  def initialize
    super
    @success_code = 200
    @headers = {'Content-Type' => 'application/vnd.collection+json'}
    @links = []
    @items = []
  end

  def add_header(key, value)
    @headers.merge!({key => value})
  end

  def success_code(code)
    @success_code = code
  end

  def add_item(href, data = [], links = [], opts = {}, &block)
    if block_given?
      item_data = Item.new(data, links)
      yield(item_data)
    end
    href = ENV['ROOT_URI'] + href
    @items << opts.merge({href: href, data: data})
  end

  class Item
    attr_reader :data, :links

    def initialize(data, links)
      @data = data
      @links = links
    end

    def add_data(name, value = '', prompt = '', opts = {})
      item_data = opts.merge({name: name})
      item_data.merge!({value: value}) if value != ''
      item_data.merge!({prompt: prompt}) if prompt != ''
      data << item_data
    end
  end

  def add_link(rel, href, opts = {})
    href = ENV['ROOT_URI'] + href
    @links << opts.merge({rel: rel, href: href})
  end

  def generate_response(href)
    collection = {href: href}
    collection.merge!({links: links}) if links.length > 0
    collection.merge!({items: items}) if items.length > 0
    response = { collection: collection }
    [@success_code, @headers, response.to_json]
  end
end
