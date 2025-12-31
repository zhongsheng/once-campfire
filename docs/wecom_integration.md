# 企业微信集成使用文档

本文档说明如何将 Campfire 与企业微信外部群机器人对接，并将消息转发到自建的 Coze Studio Agent，再将回复返回企业微信。

## 功能概览

- 接收企业微信回调（URL 验证与消息回调）
- 解密回调消息并转发至 Coze
- 将 Coze 回复发送回企业微信外部群（或应用消息）

## 回调地址

应用需要暴露以下两个回调端点：

- **URL 验证**：`GET /integrations/wecom`
- **消息回调**：`POST /integrations/wecom`

在企业微信管理后台中配置上述回调地址即可。

## 必要环境变量

以下环境变量用于企业微信与 Coze 的通信配置：

### 企业微信

- `WECOM_TOKEN`：回调 Token
- `WECOM_AES_KEY`：回调 EncodingAESKey
- `WECOM_CORP_ID`：企业 ID（corpid）
- `WECOM_CORP_SECRET`：应用 Secret
- `WECOM_AGENT_ID`：应用 AgentId

### Coze

- `COZE_API_KEY`：Coze API Key
- `COZE_BOT_ID`：Coze Bot ID
- `COZE_API_BASE_URL`（可选）：Coze API 地址，默认 `https://api.coze.com`

## 回调流程

1. 企业微信回调 `GET /integrations/wecom` 完成 URL 验证。
2. 企业微信发送消息回调 `POST /integrations/wecom`。
3. 应用解密消息并交由 `WecomMessageJob` 处理。
4. `WecomMessageJob` 调用 Coze Chat API 获取回复。
5. 应用将回复发送回企业微信外部群（或以应用消息发送给用户）。

## 发送消息规则

- 当回调消息包含 `ChatId`/`GroupChatId` 时，发送外部群消息。
- 否则，发送应用消息给 `FromUserName`。

## 本地开发与测试

```bash
bin/setup
bin/rails test
```

如果需要单独测试 WeCom 与 Coze 交互，可针对以下文件查看测试用例：

- `test/controllers/integrations/wecom_controller_test.rb`
- `test/jobs/wecom_message_job_test.rb`
- `test/lib/wecom/crypto_test.rb`
