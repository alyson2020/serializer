require 'open-uri'
require_relative '../../config/environment'

task :collect do
  item_count = Item.count
  httpc = HTTPClient.new

  # Hacker News
  page = Nokogiri::HTML(open('https://news.ycombinator.com'), nil, 'UTF-8')
  page.css('td.title > a').map do |item|
    next if item.text == 'More'
    unless item['href'].include?('http')
      item['href'] = 'https://news.ycombinator.com/' + item['href']
    end
    Item.create(url: item['href'], title: item.text.strip, source: 'hacker_news')
  end

  # Product Hunt
  page = Nokogiri::HTML(open('http://www.producthunt.com'), nil, 'UTF-8')
  page.at_css('.posts-group').css('.url').map do |post|
    Item.create(
      title: post.at_css('.title').text + ' - ' + post.at_css('.post-tagline').text,
      url: httpc.get('http://www.producthunt.com' + post.at_css('.title')['href']).header['Location'].first.to_s,
      source: 'product_hunt'
    )
  end

  # Beta List
  feed = Feedjira::Feed.fetch_and_parse('http://feeds.feedburner.com/betalist?format=xml')
  feed.entries.each do |entry|
    Item.create(
      title: entry.title + ' - ' + Nokogiri::HTML(entry.content).text.split(/,|\./).first,
      url: httpc.get(entry.id + '/visit').header['Location'].first.to_s,
      source: 'beta_list'
    )
  end

  # Reddit
  page = Nokogiri::HTML(open('http://www.reddit.com/r/programming/'), nil, 'UTF-8')
  page.css('a.title').reverse.map do |link|
    Item.create( title: link.text, url: link['href'], source: 'reddit')
  end

  puts "Created #{Item.count - item_count} items"
end
