# usage, from command line:
# > ruby define-with-twitter.rb sometag
# will print out a twitter-based definition
# cobbled together from a search for #sometag

require 'twitter_search'
require 'histogram/array'
require './lib/rubytagger_0.1.1/tagger.rb'

def histogram_hash(array)
  output = Hash.new(0)
  array.each do |x|
    output[x] += 1
  end
  output
end




client = TwitterSearch::Client.new 'making a twitter-based word definer'
tweets = client.query :q => "##{ARGV[0]}", :rpp => 50, :lang => 'en'

words = tweets.map{|x| x.text.split(/\s+/)}.flatten

h = histogram_hash(words)

#h.keys.sort_by{|key| h[key]}.reverse.each do |key|
#  puts "#{key}: #{h[key]}"
#end

# parts of speech according to rubytagger
# (at least as far as I can tell from 
# http://pages.cs.brandeis.edu/~llc/cs114/assignments/key.txt)
  # NN = noun
  # NNP = noun, proper
  # JJ = adjective
  # VBP = verb, conjugated
  # VB = verb, infinitive
  # VBD = verb, past tense
  # VBG = verb, gerund
  # IN <= "through", "with", "from" (what part of speech is that?)
# the analyzied article at that link doesn't seem to include adverbs.
# weird

# so to build a pseudo sentence I'm going to go for:
  # the quick brown fox     jumped  over the lazy dogs
  # DT  JJ    JJ    NN/NNS  VBP/VBD IN   DT  JJ   NN/NNS
# or a simpler version
  # the cat   ate the rat
  # DT  NNS?  VB. DT  NNS?  <--- see how I added those regexy things? :)
  
# hence I want to search for
  # DT ((JJ)?)* NNS? VB. (IN)? (DT)? ((JJ)?)* NNS?
  
# how the heck do I do that?

sorted_h = h.keys.map{|key| [key, h[key]]}.sort_by{|x| x[1]}.reverse

#puts "sorted_h = #{sorted_h.inspect}"

syntax_order = [
  [/DT/, :optional],
  [/JJ/, :optional],
  [/JJ/, :optional],
  [/NNS?/, :required],
  [/VB/, :required],
  #[/IN/, :optional],
  [/DT/, :optional],
  [/JJ/, :optional],
  #[/JJ/, :optional],
  [/NNS?/, :required],
]

# I'm thinking I'll do a descending search through the array once for 
# each syntax element.  If I find a word that works, I'll yank it out
# and insert it into the definition.
# not sure yet how I'm going to handle the optional parts

output = []
tagger = Tagger.new('./lib/rubytagger_0.1.1/lexicon.txt')

BORING_WORDS = ['was', 'com', 'an', 'is', 'con', 'da', 'van']
def the_word_matches(pos_tag, chunk, word)
  pos_tag =~ chunk[0] and 
  word[0].size > 1 and 
  !BORING_WORDS.include?(word[0]) and
  word[0] !~ /^[A-Z]+$/ and # no acronyms!
  true
end

syntax_order.each_with_index do |chunk, index|
  if index == syntax_order.size - 1 or chunk[1] == :required
    # must find the next word of that type
      
    sorted_h.each_with_index do |word, word_index|
      pos_tag_array = tagger.getTags(word)
      pos_tag = pos_tag_array[0].to_s
      if the_word_matches(pos_tag, chunk, word)
        output << word[0].downcase
        sorted_h.delete_at(word_index)
        break
      end
    end
    #output << "<not_found: #{x[0]}>"
  else
    # find the next word of that type or the next required, 
    # whicever comes first.
    rest_of_syntax_order = syntax_order.slice(index .. syntax_order.size - 1)
    next_required = rest_of_syntax_order.select{|x| x[1] == :required}[0]
      
    sorted_h.each_with_index do |word, word_index|
      pos_tag_array = tagger.getTags(word)
      pos_tag = pos_tag_array[0].to_s
      if the_word_matches(pos_tag, chunk, word)
        output << word[0].downcase
        sorted_h.delete_at(word_index)
        break
      end
      if the_word_matches(pos_tag, next_required, word)
        output << word[0].downcase
        sorted_h.delete_at(word_index)
        break
      end
    end
  end
end

puts "definition of #{ARGV[0]}: '#{output.join(' ')}'"

puts "\n\n"

# dan taub:
# read emotional impact of words

