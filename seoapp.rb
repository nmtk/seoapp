# encoding: UTF-8
require 'json'
require 'sinatra'
require "sinatra/reloader" if development?
require 'mysql2'
require 'erubis'
set :erb, :escape_html => true
require 'net/http'
require 'uri'
require 'open-uri'
require 'pp'
require 'rexml/document'
USER_AGENT = "iTunes-iPhone/4.2.1 (2; 8GB)"

pp "firsttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt"

=begin
# 最初にDBを接続する
before do
    if ENV['RACK_ENV'].blank? && ENV["CLEARDB_DATABASE_URL"].blank? then
        database_config = { :host => "localhost", :username => "root", :password => "rappuppu", :database => "seoapp_development" }
        else
        parse_uri = URI.parse(ENV["CLEARDB_DATABASE_URL"])
        username  = parse_uri.user
        password  = parse_uri.password
        host      = parse_uri.host
        database  = parse_uri.path[1..-1]
        reconnect = parse_uri.query == "reconnect=true"
        database_config = { :host => host, :username => username, :password => password, :database => database, :reconnect => reconnect }
    end
    
    @db = Mysql2::Client.new(database_config)
end

# 最後にDBを切断する
after do
    @db.close if @db
end
=end

#ID入力用のテキストフォーム
get '/' do
    erb :index
end

#ID入力後
get '/ranking/information' do
    @id = params[:id] #TODO:フォームからパラメータを受け取る
    #if @id == ""
    #return erb :index
    #break
    #end
    pp "###########################################################################################"
    pp @id
    
    if @id == ""
        return erb :index
    end
    
    if /^[0-9]{9}?$/ !~ @id.to_s
        return erb :index
    end
    
    #if @id.size <= 8 or 10 <= @id.size
    #return erb :index
    #break
    #end
    
    Net::HTTP.start("itunes.apple.com"){ |http| #Net:HTTPサーバを開始する
        pp http
        request = Net::HTTP::Get.new "/lookup?country=JP&id=#{@id}" #TODO:リクエストURLを組み立てる
        #pp request
        request.add_field "User-Agent", "User-Agent: iTunes-iPhone/4.2.1 (2; 8GB)"
        #pp request
        request.add_field "X-Apple-Store-Front", "143462-9" #TODO:Search APIを呼び出す
        #pp request
        response = http.request(request) #TODO:ウェブサーバーからアプリの情報を得る
        #pp response
        #pp response.class
        #@res = response.class
        #if @res == Net::HTTPBadRequest
        #return erb :index
        #break
        #end
        output = response.body #JSONの文字列を開く
        #pp output
        parsed_json = JSON.parser.new(output).parse() #JSONの文字列を解析してデータ構造に変換する
        #pp parsed_json.class
        #pp parsed_json.size
        #json = parsed_json["artworkUrl60"]
        #pp json
        pp parsed_json["results"].class
        results = parsed_json["results"]
        pp results.assoc("artworkUrl60")
        pp results.count
        @result = results.count
        if @result == 0
            return erb :index
        end
        app = results[0]
        #pp app
        rslt = app["artworkUrl60"]
        name = app["trackName"]
        
        @image_url = rslt
        @artistName = name
            
        erb :search
    }
end

get '/appid' do
    erb :appid
end

get '/howtouse' do
    erb :howtouse
end

get '/tos' do
    erb :tos
end

get '/privacy' do
    erb :privacy
end


#検索ワード入力後
get '/ranking/result' do
    pp "7777777777777777777777777777777777777777777777777777777777"
    @id = params[:id] #TODO:フォームからパラメータを受け取る
    pp @id
    Net::HTTP.start("itunes.apple.com"){ |http| #Net:HTTPサーバを開始する
        request = Net::HTTP::Get.new "/lookup?country=JP&id=#{@id}" #TODO:リクエストURLを組み立てる
        request.add_field "User-Agent", "User-Agent: iTunes-iPhone/4.2.1 (2; 8GB)"
        request.add_field "X-Apple-Store-Front", "143462-9" #TODO:Search APIを呼び出す
        response = http.request(request) #TODO:ウェブサーバーからアプリの情報を得る
        output = response.body #JSONの文字列を開く
        parsed_json = JSON.parser.new(output).parse() #JSONの文字列を解析してデータ構造に変換する
        results = parsed_json["results"]
        app = results[0]
        rslt = app["artworkUrl60"]
        name = app["trackName"]
        @image_url = rslt
        @artistName = name
        @image_url2 = @image_url#TODO:アプリのアイコンの取得
        @artistName2 = @artistName#TODO:アプリ名の取得
    }
        pp @image_url2
        pp @artistName2
    
    # 結果（キーワード）表示用の配列
    @keywords = Array.new
    
    # 検索用の配列
    keywords2 = Array.new
    
    # 結果（順位）表示用の配列
    @ranks = Array.new
    
    @keyword = params[:word]#TODO:フォームからパラメータ（検索キーワード）を取得する
    
    # キーワードを「,」で分ける
    @keyword1 = @keyword.split(",")
    
    # キーワードに含まれる半角スペースと改行を削除
    @keyword2 = @keyword.delete(" ")
    #@keyword2 = @keyword2.delete("\")
    @keyword2 = @keyword2.delete("\r\n")
    
    # キーワードを「,」で分ける
    @keyword2 = @keyword2.split(",")
    
    
    pp @keyword1
    pp @keyword2
    
    # 結果表示用の配列の作成
    @keywords << @keyword1
    pp @keywords[0]
    output = nil
    
    #for i in 0..keywords[0].size - 1 do
    #keywords[0].size.each do |i|
    
    # キーワード毎に順位を出す
    @keyword2.each do |keyword|
        
        Net::HTTP.start("search.itunes.apple.com"){ |http| #TODO:Net:HTTPサーバを開始する
            request = Net::HTTP::Get.new "/WebObjects/MZSearch.woa/wa/search?submit=edit&term=#{keyword}" #TODO:リクエストURLを組み立てる
                #pp request.methods
                #pp request.path
                #pp request
        
            request.add_field "User-Agent", "User-Agent: iTunes-iPhone/6.0.0 (2; 8GB)"
                # 143462が国コードに本、9が言語コード日本語

            request.add_field "User-Agent", "iTunes/11.0.4 (Macintosh; OS X 10.8.4) AppleWebKit/536.30.1"
                # 143462が国コードに本、9が言語コード日本語
                #request.add_field "X-Apple-Store-Front", "143462-9"#TODO:Search APIを呼び出す
            request.add_field "X-Apple-Store-Front", "143462-9,17"
            response = http.request(request) #TODO:ウェブサーバーからアプリの情報を得る
            output = response.body#TODO:XMLの文字列を開く
        }   #ウェブサーバからドキュメントを得る
        
            # HTMLの中から平文のJSONを取得する
        pp "#####################"
        plain_text_json = output.scan(/its.serverData=.*?<\/script>/)[0]
        if plain_text_json == nil
            @rank = "ランク外"
            @ranks << @rank
        else
            
            # あるとJSONとして認識してもらえない余分な単語を外す
            plain_text_json = plain_text_json.gsub("its\.serverData=", '').strip
            plain_text_json = plain_text_json.gsub("<\/script>", '').strip
    
            # 平文のJSONをパースする
            parsed_json = JSON.parse(plain_text_json)
    
            #parsed_json["pageData"]["storePlatformData"]["lockup"]["results"]["493470467"]
            #parsed_json["pageData"]["searchPageData"]["bubbles"][0]["results"]
            pp "==============="
        
            # 検索順位の判定
            if parsed_json["pageData"]["searchPageData"]["bubbles"][0] == nil
                @rank = "ランク外"
                @ranks << @rank
            else
                for i in 0..parsed_json["pageData"]["searchPageData"]["bubbles"][0]["results"].size do
                    if parsed_json["pageData"]["searchPageData"]["bubbles"][0]["results"][i] != {"id"=>@id, "entity"=>"software"} then
                        i = i + 1
                    else
                        i = i + 1
                        @rank = i
                        @ranks << @rank
                        break
                    end
                    if i == parsed_json["pageData"]["searchPageData"]["bubbles"][0]["results"].size + 1
                        @rank = "ランク外"
                        @ranks << @rank
                    end
                end
            end
        end
    end

=begin
        #pp output
        pp output.class
        
        #pp @xml_text = output.encode("UTF-8", :invalid => :replace, :undef => :replace, :replace => "")
        
        # pp output.class
        # アプリの情報を保存するための配列を用意
        apps = Array.new
        # アプリのIDを保存するための配列を用意
        appIds = Array.new
        
        doc = REXML::Document.new(output)
        pp doc
        pp doc.elements
        doc.elements.each('document/pictureview/tracklist/plist/true') do |element|
            for i in 0..element.elements.size do
                # XMLの構造によってはエラーが発生する可能性があるため、エラーをキャッチする
                # アプリの情報を保存するためのハッシュマップを用意
                app = Hash.new
                begin
                    # TODO: アプリの情報をappに入れる
                    app["num"] = i
                    # XMLエレメントを表示
                    element.elements.each('integer') do |integer|
                        # 9桁だったらアプリのID
                        value = integer.text.to_i
                        if value > 99999999 and value < 1000000000 then
                            appIds.push value
                        end
                    end
                    pp element.elements[i]
                    rescue => e
                    # キャッチしたエラーを無視する
                end
                apps.push app
            end
            end
            
            pp appIds.uniq
            pp appIds.uniq.size
            
        
            for i in 0..appIds.size do
                if appIds[i] != @id then
                    i = i + 1
                else
                    rank = i
                    pp rank
                end
            end
        
            #pp @doc.methods
            #pp @doc.elements
            #pp @doc.root
            #pp @doc.get_text
            #pp @doc
            #pp @doc.class
    }
    #TODO:XMLの文字列を解析してデータ構造に変換する
    #TODO:順位の取得
=end
        
    erb :result
end




#rubyでjsonをつくる
#簡単なjsonをつくる（配列一つみたいなやつ）
#簡単なjsonをパースする
#複雑なjson（二重配列とか）を作ってパースする        