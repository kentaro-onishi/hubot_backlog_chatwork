# Description:
#   Backlog to Slack
#
# Commands:
#   None

backlogUrl = 'https://renoco2.backlog.jp/'
chatworkApiUrl = 'https://api.chatwork.com/v1'

module.exports = (robot) ->
  chatworkPost = (message) ->
    robot.logger.error "#{process.env.HUBOT_CHATWORK_ROOMS}"
    robot.http("#{chatworkApiUrl}/rooms/#{process.env.HUBOT_CHATWORK_ROOMS}/messages")
      .headers
        'Content-Type': 'application/x-www-form-urlencoded'
        'X-ChatWorkToken': process.env.HUBOT_CHATWORK_TOKEN
      .post('body=' + message) (err, r, body) ->
        robot.logger.error "Chatwork error:#{err}, body:#{body}" if err?
  robot.router.post "/postchatwork/:room", (req, res) ->
    { room } = req.params
    { body } = req
    try

      switch body.type
          when 1
              label = '課題の追加'
          when 2, 3
              # 「更新」と「コメント」は実際は一緒に使うので、一緒に。
              label = '課題の更新'
          when 5
              label = 'wikiの追加'
          when 6
              label = 'wikiの更新'
          when 8
              label = 'ファイルの追加'
          when 9
              label = 'ファイルの更新'
          else
              # 課題関連以外はスルー

      # 投稿メッセージを整形
      url = "#{backlogUrl}view/#{body.project.projectKey}-#{body.content.key_id}"
      if body.content.comment?.id?
          url += "#comment-#{body.content.comment.id}"

      message = "*Backlog #{label}*\n"
      message += "[#{body.project.projectKey}-#{body.content.key_id}] - "
      message += "#{body.content.summary} _by #{body.createdUser.name}_\n>>> "
      if body.content.comment?.content?
          message += "#{body.content.comment.content}\n"
      message += "#{url}"

      # Chatwork に投稿
      if message?
          robot.logger.error "pre #{message}"
          chatworkPost message
          res.send "OK"
      else
          robot.messageRoom room, "Backlog integration error."
          res.end "Error"
    catch error
      robot.logger.error "error catch"
      robot.send
      res.end "Error"
