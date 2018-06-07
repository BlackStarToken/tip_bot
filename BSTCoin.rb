# BST用クラス

class BSTCoin

    def initialize()
        @fromAddress = ENV["FROM_ADDRESS"]
        @fromeaccount = ENV["FROM_ACCOUNT_NAME"]
        @contractAddress = ENV["CONTRACT_ADDRESS"]
    end
   
    # BST残高確認
    def balance(address)
        # アドレス変換
        hexAddress = `VIPSTARCOIN-cli gethexaddress #{address}`
        # data作成
        data = `ethabi encode function ./interface.json balanceOf #{hexAddress}`
        command = "VIPSTARCOIN-cli callcontract #{@contractAddress} #{data}"
        # p command
        ret = `#{command}`
        ret = JSON.parse(ret)
        # p ret
        ret["executionResult"]["output"].to_i(16)
        amount_str = ret["executionResult"]["output"].to_i(16).to_s
        len = amount_str.length
        if len <= 18
            add_count = 19 - len
            (1..add_count).each { |i| amount_str.insert(0, "0") }
        end
        amount_str.insert(-19, ".").to_f
    end
    
    # VIPSの残高確認
    def vips_balance(account)
        command = "VIPSTARCOIN-cli getbalance #{account}"
        `#{command}`.gsub("\n", "").to_f
    end
    
    # アドレス作成
    def create_address(account = "")
        command = "VIPSTARCOIN-cli getnewaddress #{account}"
        ret = `#{command}`.gsub("\n", "")
    end
    
    # 送金用コマンド作成
    def send(sender_address, receiver_address, amount)
        # アドレス変換
        hexAddress = `VIPSTARCOIN-cli gethexaddress #{receiver_address}`
        # 送金量変換
        convertedAmount = convertAmount(amount)
        # コマンド作成
        command = "VIPSTARCOIN-cli sendtocontract #{@contractAddress} a9059cbb000000000000000000000000#{hexAddress}#{convertedAmount} 0 250000 0.0000004 #{sender_address}"
        command.gsub!("\n", '')
        # コマンド実行
        ret = `#{command}`
    end
    
    # VIPSの送金
    def send_vips(receiver_address, amount)
        command = "VIPSTARCOIN-cli sendfrom #{@fromeaccount} #{receiver_address} #{amount}"
        ret = `#{command}`
    end
    
    private
    
    def convertAmount(amount)
        amount *= 10**18
        hex = amount.to_i.to_s(16)
        str = "0" * (64 - hex.length) + hex
    end


end