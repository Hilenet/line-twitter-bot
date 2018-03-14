require 'json'
require 'singleton'

# json(のhash)を持ってる
class Template
  include Singleton

  def initialize
    Dir.glob("templates/*json").each do |f|
      # jsonをhashにパース
      json = nil
      File.open(f) do |io|
        json = JSON.load(io)
      end
      hash = json.to_hash

      # ファイル名の変数としてhashを格納
      val = f[10...-5]
      instance_variable_set("@#{val}", hash)

      # 同名の関数でcloneを返すように
      self.class.send(:define_method, val) do
        # 深いコピーの為に文字列にバラす(FileIOよりまし・・・)
        eval("Marshal.load(Marshal.dump(@#{val}))")
      end
    end
  end

end
