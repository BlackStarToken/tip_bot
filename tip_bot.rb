require 'discordrb'
require 'net/http'
require './tip.rb'

bot = Discordrb::Bot.new token: ENV['TIP_BOT_TOKEN']

def mension(to_id)
    "<@!#{to_id}>"
end

# スタンプメッセージ表示チャンネルID
stamp_log_channel_id = ENV["STAMP_LOG_CHANNEL_ID"]
command_channel_id = ENV["COMMAND_CHANNEL_ID"]

# エラーメッセージ
invalid_command = "コマンドが異常です"

# スタンプ用イベントハンドラ設定
bot.reaction_add({emoji: "tip1"}) do |event|
    tip = Tip.new
    send_user_id = event.user.id.to_s
    receive_user_id = event.message.author.id.to_s
    
    tip.tip(send_user_id, receive_user_id, 1, true)
    bot.send_message(channel_id=stamp_log_channel_id, tip.message)
end
bot.reaction_add({emoji: "tip10"}) do |event|
    tip = Tip.new
    send_user_id = event.user.id.to_s
    receive_user_id = event.message.author.id.to_s
    
    tip.tip(send_user_id, receive_user_id, 10, true)
    bot.send_message(channel_id=stamp_log_channel_id, tip.message)
end
bot.reaction_add({emoji: "tip100"}) do |event|
    tip = Tip.new
    send_user_id = event.user.id.to_s
    receive_user_id = event.message.author.id.to_s
    
    tip.tip(send_user_id, receive_user_id, 100, true)
    bot.send_message(channel_id=stamp_log_channel_id, tip.message)
end
bot.reaction_add({emoji: "tip1000"}) do |event|
    tip = Tip.new
    send_user_id = event.user.id.to_s
    receive_user_id = event.message.author.id.to_s
    
    tip.tip(send_user_id, receive_user_id, 1000, true)
    bot.send_message(channel_id=stamp_log_channel_id, tip.message)
end
bot.reaction_add({emoji: "tip9999"}) do |event|
    tip = Tip.new
    send_user_id = event.user.id.to_s
    receive_user_id = event.message.author.id.to_s
    
    tip.tip(send_user_id, receive_user_id, 9999, true)
    bot.send_message(channel_id=stamp_log_channel_id, tip.message)
end

# コマンド

bot.message() do |event|
    if event.channel.id.to_s == command_channel_id
        tip = Tip.new
        # コマンド判別
        # コマンド発行ユーザ
        user = event.user
        message = event.message.content
        command = message.split(" ")[0]
        if command == "./balance"
            tip.balance(user.id)
            event.respond tip.message
        elsif command == "./tip"
            begin
                send_user_id = user.id
                receive_user_id = message.split(" ")[1][2, 18]
                amount = message.split(" ")[2]
                if send_user_id.to_s.length == 0 || receive_user_id.to_s.length == 0
                    event.respond mension(send_user_id) + "さん\n" + invalid_command
                else
                    if tip.tip(send_user_id, receive_user_id, amount.to_f, false)
                        event.respond tip.message
                    else
                        event.respond mension(send_user_id) + "さん\n手数料が補充されていません。手数料が補充されるまで暫くお待ちください。"
                    end
                end
            rescue NoMethodError => e
                p e
                event.respond mension(send_user_id) + "さん\n" + invalid_command
            end
        elsif command == "./withdraw"
            begin
                send_user_id = user.id
                receiver_address = message.split(" ")[1]
                amount = message.split(" ")[2]
                tip.withdraw(send_user_id, receiver_address, amount)
                event.respond tip.message
            rescue => e
                p e
            end
        elsif command == "./record"
            user_id = user.id
            begin
                tip.get_log(user_id)
                event.respond tip.message
            rescue => e
                p e
            end
        elsif command == "./help"
            tip.help(user.id)
            event.respond tip.message
        elsif command == "./deposit"
            tip.deposit(user.id)
            event.respond tip.message
        end
    end
end

bot.run