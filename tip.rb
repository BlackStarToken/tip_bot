require 'net/http'
require 'json'
require 'uri'
require 'sqlite3'
require "./Wallet.rb"

class Tip
    
    attr_reader :message 
    
    def initialize()
        @db = SQLite3::Database.new 'tip_bot.db'
        @wallet = Wallet.new
        @message = ""
        @balance = 0
        
        @replenish_fee_amount = 20
    end
    
    # ディスコ内ウォレットのアドレスを表示
    def deposit(user_id)
        @message = mension(user_id) + "さんのアドレスは " + address_by_user_id(user_id) + " です"
    end
    
    # BST残高確認
    def balance(user_id)
        if is_exists_wallet(user_id)
            sql = "select address from wallets where user_id = \"#{user_id}\";"
            row = @db.execute(sql)
            address = row[0][0]
            ret = @wallet.balance(address)
        else
            address = create_wallet(user_id)
            ret = @wallet.balance(address)
        end
    
        @message = mension(user_id) + "さんの残高は #{ret} BST です"
        
        ret
    end
    
    # 手数料残高確認
    def vips_balance(user_id)
        if !is_exists_wallet(user_id)
            create_wallet(user_id)
        end
        @wallet.vips_balance(user_id)
    end
    
    def tip(send_user_id, receive_user_id, amount, is_stamp)
        # 送金者のBST残高を確認
        if balance(send_user_id) < amount
            puts "エラー：送金者のBSTが足りません"
            @message = mension(send_user_id) + "さん\n BSTの残高が足りません"
            return false
        end
        # 送金者の手数料残高を確認
        if vips_balance(send_user_id) < 10
            puts "警告：送金者の手数料が残り少ないです"
            replenish_fee(send_user_id)
            puts "ユーザID: #{send_user_id} の手数料を補充しました"
        end
        if vips_balance(send_user_id) < 0.1
            puts "警告：送金手数料が足りていません"
            @message = mension(send_user_id) + "さん\n 手数料が足りません、手数料が補充されるまでしばらくお待ちください"
            return false
        end
        # 受け取り人のアドレス確認
        balance(receive_user_id)
        # 送金
        sender_address = address_by_user_id(send_user_id)
        receiver_address = address_by_user_id(receive_user_id)
        @wallet.send(sender_address, receiver_address, amount)
        # ログに記入
        if is_stamp
            logging("stamp", amount.to_s, sender_address, receiver_address)
        else
            logging("tip", amount.to_s, sender_address, receiver_address)
        end
        # メッセージ
        @message = mension(send_user_id) + " さんから " + mension(receive_user_id) + " さんへ #{amount} BSTが送られました"
    end
    
    def withdraw(send_user_id, receiver_address, amount)
        # puts "withdrawしました"
        if balance(send_user_id) < amount.to_f
            puts "エラー：送金者のBSTが足りません"
            @message = mension(send_user_id) + "さん\n BSTの残高が足りません"
            return false
        end
        # puts "withdrawしました2"
        # 送金
        if vips_balance(send_user_id) < 5
            puts "警告：送金者の手数料が残り少ないです"
            replenish_fee(send_user_id)
            puts "ユーザID: #{send_user_id} の手数料を補充しました"
        end
        if vips_balance(send_user_id) < 0.1
            puts "警告：送金手数料が足りていません"
            @message = mension(send_user_id) + "さん\n 手数料が足りません、手数料が補充されるまでしばらくお待ちください"
            return false
        end
        # puts "withdrawしました3"
        sender_address = address_by_user_id(send_user_id)
        @wallet.send(sender_address, receiver_address, amount.to_f)
        # メッセージをセット
        # ログに記入
        logging("withdraw", amount.to_s, sender_address, receiver_address)
        # メッセージ
        @message = mension(send_user_id) + "さん\n" + "指定したアドレスへ #{amount.to_s} BSTが送られました"
        # puts "withdrawしました4"
    end
    
    # 手数料を補充する
    def replenish_fee(user_id)
        # 指定ユーザにVIPSを送金
        to_address = address_by_user_id(user_id)
        @wallet.send_vips(to_address, @replenish_fee_amount)
    end
    
    # 指定ユーザのウォレットが存在するかの確認
    def is_exists_wallet(user_id)
        sql = "select count(*) from wallets where user_id = \"#{user_id}\";"
        row = @db.execute(sql)
        ret = row[0][0]
        if ret == 0
            false
        else
            true
        end
    end
    
    # ユーザIDからアドレスを参照
    def address_by_user_id(user_id)
        sql = "select address from wallets where user_id = \"#{user_id}\""
        row = @db.execute(sql)
        row[0][0]
    end
    
    # 指定ユーザのウォレットを作成する
    def create_wallet(user_id)
        address = @wallet.create_address(user_id)
        begin
            sql = "insert into wallets(user_id, address) values(\"#{user_id}\", \"#{address}\");"
            @db.execute(sql)
        rescue => e
            p e
        end
        
        address
    end
    
    # private
    
    def mension(to_id)
        "<@!#{to_id}>"
    end
    
    def get_user(user_id)
    
        uri = URI.parse('https://discordapp.com/api/users/' + user_id.to_s)
        
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        header = {'Authorization' => 'Bot ' + ENV['TIP_BOT_TOKEN']}
        res = https.start {
          https.get(uri.request_uri, header)
        }
        
        JSON.parse(res.body)
    end
    
    def logging(order_kind, amount, sended_address, sent_address)
        begin
            sql = "insert into log(order_kind, amount, sended_address, sent_address) 
                                values (\"#{order_kind}\", \"#{amount}\", \"#{sended_address}\", \"#{sent_address}\")"
            @db.execute(sql)
        rescue => e
            p e
        end
    end
    
    def get_log(user_id)
        user_address = address_by_user_id(user_id)
        # 指定したユーザのログを返す
        # 投げ銭した回数
        sql = "select count(*) from log where order_kind = \"tip\" and sended_address = \"#{user_address}\""
        send_tip_count = @db.execute(sql)[0][0]
        
        # 投げ銭したBST
        sql = "select sum(amount) from log where order_kind = \"tip\" and sended_address = \"#{user_address}\""
        send_tip_sum = @db.execute(sql)[0][0]
        
        # 投げられた回数
        sql = "select count(*) from log where order_kind = \"tip\" and sent_address = \"#{user_address}\""
        receive_tip_count = @db.execute(sql)[0][0]
        
        # 投げられたBST
        sql = "select sum(amount) from log where order_kind = \"tip\" and sent_address = \"#{user_address}\""
        receive_tip_sum = @db.execute(sql)[0][0]
        
        # 1TIPスタンプした回数
        sql = "select count(*) from log where order_kind = \"stamp\" and sended_address = \"#{user_address}\" and amount = \"1\""
        send_1stamp_count = @db.execute(sql)[0][0]
        
        # 1TIPスタンプされた回数
        sql = "select count(*) from log where order_kind = \"stamp\" and sent_address = \"#{user_address}\" and amount = \"1\""
        receive_1stamp_count = @db.execute(sql)[0][0]
        
        # 10TIPスタンプした回数
        sql = "select count(*) from log where order_kind = \"stamp\" and sended_address = \"#{user_address}\" and amount = \"10\""
        send_10stamp_count = @db.execute(sql)[0][0]
        
        # 10TIPスタンプされた回数
        sql = "select count(*) from log where order_kind = \"stamp\" and sent_address = \"#{user_address}\" and amount = \"10\""
        receive_10stamp_count = @db.execute(sql)[0][0]
        
        # 1000TIPスタンプした回数
        sql = "select count(*) from log where order_kind = \"stamp\" and sended_address = \"#{user_address}\" and amount = \"1000\""
        send_100stamp_count = @db.execute(sql)[0][0]
        
        # 1000TIPスタンプされた回数
        sql = "select count(*) from log where order_kind = \"stamp\" and sent_address = \"#{user_address}\" and amount = \"1000\""
        receive_100stamp_count = @db.execute(sql)[0][0]
        
        # 100TIPスタンプした回数
        sql = "select count(*) from log where order_kind = \"stamp\" and sended_address = \"#{user_address}\" and amount = \"100\""
        send_100stamp_count = @db.execute(sql)[0][0]
        
        # 100TIPスタンプされた回数
        sql = "select count(*) from log where order_kind = \"stamp\" and sent_address = \"#{user_address}\" and amount = \"100\""
        receive_100stamp_count = @db.execute(sql)[0][0]
        
        # 9999TIPスタンプした回数
        sql = "select count(*) from log where order_kind = \"stamp\" and sended_address = \"#{user_address}\" and amount = \"9999\""
        send_9999stamp_count = @db.execute(sql)[0][0]
        
        # 9999TIPスタンプされた回数
        sql = "select count(*) from log where order_kind = \"stamp\" and sent_address = \"#{user_address}\" and amount = \"9999\""
        receive_9999stamp_count = @db.execute(sql)[0][0]
        
        # メッセージ作成
        @message = mension(user_id) + "さんの記録\n" +
                    "投げ銭した回数\n#{send_tip_count}回\n" +
                    "投げ銭したBST\n#{send_tip_sum}BST\n" +
                    "投げられた回数\n#{receive_tip_count}回\n" +
                    "投げられたBST\n#{receive_tip_sum}BST\n" +
                    "1TIPスタンプした回数\n#{send_1stamp_count}回\n" +
                    "1TIPスタンプされた回数\n#{receive_1stamp_count}回\n" +
                    "10TIPスタンプした回数\n#{send_10stamp_count}回\n" +
                    "10TIPスタンプされた回数\n#{receive_10stamp_count}回\n" +
                    "100TIPスタンプした回数\n#{send_100stamp_count}回\n" +
                    "100TIPスタンプされた回数\n#{receive_100stamp_count}回\n" +
                    "9999TIPスタンプした回数\n#{send_9999stamp_count}回\n" +
                    "9999TIPスタンプされた回数\n#{receive_9999stamp_count}回\n"
    end
    
    def help(user_id)
        @message = mension(user_id) + "./balance
残高を返します

./deposit
入金用アドレスを返します

./record
記録を返します

./tip (@対象) (金額)
指定したユーザーに指定金額のBSTを送ります

./withdraw (アドレス) (金額)
指定したアドレスに指定金額のBSTを送ります"
    end
    
end