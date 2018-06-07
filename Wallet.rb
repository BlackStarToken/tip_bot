require 'json'
require './BSTCoin.rb'

class Wallet
    
    def initialize
        @BSTCoin = BSTCoin.new
    end
    
    # BST残高確認
    def balance(address)
        @BSTCoin.balance(address)
    end
    
    # VIPS残高確認
    def vips_balance(user_id)
        @BSTCoin.vips_balance(user_id)
    end
    
    # アドレス作成
    def create_address(account)
        @BSTCoin.create_address(account)
    end
    
    # 送金
    def send(sender_address, receiver_address, amount)
        @BSTCoin.send(sender_address, receiver_address, amount)
    end
    
    # VIPSの送金
    def send_vips(receiver_address, amount)
        @BSTCoin.send_vips(receiver_address, amount)
    end
    
end