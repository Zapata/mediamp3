class MediaEncoder
  def encode(article)
    beginning_time = Time.now
    content_file = article.path('txt')
    audio_file = article.path('mp3')

    print "Encoding '#{article.title}' into #{audio_file} ... "

    File.open(content_file, "w:Windows-1252") do |f| 
      f.write(article.content.encode('Windows-1252', :invalid => :replace, :undef => :replace, :replace => ''))
    end
    
    balabolka_cmd = "bin\\balabolka_console.exe -o --raw -f #{content_file} "
    lame_cmd = "bin\\lame.exe -r --silent -s 16 -m m -h - #{audio_file}"
    lame_cmd <<= " --ta MediaMp3" # Artist.
    lame_cmd <<= " --tl #{article.source}" # Album
    lame_cmd <<= " --tt \"#{article.title}\"" # Title
    
    `#{balabolka_cmd} | #{lame_cmd}`
    
    end_time = Time.now
    print "done in #{(end_time - beginning_time)}s.\n"
  end
end
