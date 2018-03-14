# line-twitter-bot
## about 
line bot for twitter
lineからいい感じにTwitterと連携してごにょるクライアント

## usage
1. lineのDeveroper_Trialか何かで`PUSH_MESSAGE`権限のあるLINE@アカウント登録
2. TwitterでR/W権限のあるアプリとして登録
3. 公開用hostに乗せて，conf/\*.env.tmpからconf/\*.envを作成
4. `docker-compose up`

## db
### Redis
line_id | {twitter_access_token, twitter_access_secret}

## TODO
* リプライ機能が未実装(UIが全く思いつかない)
* 画像表示，サムネ，本Tweetへのリンクなど
* UI


