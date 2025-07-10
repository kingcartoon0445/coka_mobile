# Hướng dẫn gửi Payload FCM để điều hướng trong Coka-Mobile

> File này liệt kê **toàn bộ** giá trị `route` và các tham số cần thiết mà Backend phải thêm vào phần `data` của FCM notification để app Coka-Mobile điều hướng chính xác khi người dùng nhấn vào thông báo.

---

## 1. Quy tắc chung

| Khóa | Bắt buộc | Ý nghĩa |
|------|----------|---------|
| `route` | **Có** | Tên route (xem bảng chi tiết bên dưới) |
| `organizationId` | **Có** | ID tổ chức |
| Tham số khác | Tuỳ | Tùy route (ví dụ `workspaceId`, `customerId` …) |
| `notificationId` | Tuỳ | Nếu gửi, client sẽ **đánh dấu đã đọc** notification |

Thiếu **bất kỳ** tham số bắt buộc nào → Client sẽ fallback về `/organization/{organizationId}`.

---

## 2. Bảng mapping `route` → URL

| `route` | Tham số bổ sung PHẢI có | URL client mở |
|---------|-------------------------|---------------|
| `organization` | – | `/organization/{organizationId}` |
| `messages` | – | `/organization/{organizationId}/messages` |
| `message_settings` | – | `/organization/{organizationId}/messages/settings` |
| `chat_detail` | `conversationId` | `/organization/{organizationId}/messages/detail/{conversationId}` |
| `campaigns` | – | `/organization/{organizationId}/campaigns` |
| `ai_chatbot` | – | `/organization/{organizationId}/campaigns/ai-chatbot` |
| `create_chatbot` | – | `/organization/{organizationId}/campaigns/ai-chatbot/create` |
| `edit_chatbot` | `chatbotId` | `/organization/{organizationId}/campaigns/ai-chatbot/edit/{chatbotId}` |
| `multi_source_connection` | – | `/organization/{organizationId}/campaigns/multi-source-connection` |
| `fill_data` | – | `/organization/{organizationId}/campaigns/fill-data` |
| `automation` | – | `/organization/{organizationId}/campaigns/automation` |
| `notifications` | – | `/organization/{organizationId}/notifications` |
| `settings` | – | `/organization/{organizationId}/settings` |
| `invitations` | – | `/organization/{organizationId}/invitations` |
| `join_requests` | – | `/organization/{organizationId}/join-requests` |
| `workspace` | `workspaceId` | `/organization/{organizationId}/workspace/{workspaceId}` |
| `customers` | `workspaceId` | `/organization/{organizationId}/workspace/{workspaceId}/customers` |
| `customer_detail` | `workspaceId`, `customerId` | `/organization/{organizationId}/workspace/{workspaceId}/customers/{customerId}` |
| `add_customer` | `workspaceId` | `/organization/{organizationId}/workspace/{workspaceId}/customers/new` |
| `edit_customer` | `workspaceId`, `customerId` | `/organization/{organizationId}/workspace/{workspaceId}/customers/{customerId}/edit` |
| `customer_basic_info` | `workspaceId`, `customerId` | `/organization/{organizationId}/workspace/{workspaceId}/customers/{customerId}/basic-info` |
| `customer_reminders` | `workspaceId`, `customerId` | `/organization/{organizationId}/workspace/{workspaceId}/customers/{customerId}/reminders` |
| `import_googlesheet` | `workspaceId` | `/organization/{organizationId}/workspace/{workspaceId}/customers/import-googlesheet` |
| `teams` | `workspaceId` | `/organization/{organizationId}/workspace/{workspaceId}/teams` |
| `team_detail` | `workspaceId`, `teamId` | `/organization/{organizationId}/workspace/{workspaceId}/teams/{teamId}` |
| `reports` | `workspaceId` | `/organization/{organizationId}/workspace/{workspaceId}/reports` |

### Lưu ý đặc biệt

1. `chat_detail` cần hiển thị **MessagesPage → ChatDetailPage** để nút Back hoạt động. Client tự thêm bước `push`, BE **không cần** thay đổi gì.
2. Các route **ngoài ShellRoute** (`multi_source_connection`, `fill_data`, `automation`) sẽ được client push sau khi mở trang Campaigns để Back quay lại tab Campaigns.

---

## 3. Ví dụ payload hoàn chỉnh

### Tin nhắn mới
```json
{
  "notification": {
    "title": "Tin nhắn mới",
    "body": "Khách hàng A vừa nhắn tin"
  },
  "data": {
    "route": "chat_detail",
    "organizationId": "org_123",
    "conversationId": "conv_456",
    "workspaceId":"123zxc",
    "notificationId": "notif_999"
  },
  "to": "<FCM_TOKEN>"
}
```

### Lời mời tham gia tổ chức
```json
{
  "notification": {
    "title": "Lời mời mới",
    "body": "Bạn có lời mời tham gia tổ chức ABC"
  },
  "data": {
    "route": "invitations",
    "organizationId": "org_123",
    "notificationId": "inv_456",
    "inviterName": "Nguyễn Văn A",
    "invitationType": "organization"
  },
  "to": "<FCM_TOKEN>"
}
```

### Yêu cầu gia nhập tổ chức
```json
{
  "notification": {
    "title": "Yêu cầu gia nhập mới",
    "body": "Lê Thị B muốn tham gia tổ chức của bạn"
  },
  "data": {
    "route": "join_requests",
    "organizationId": "org_123",
    "notificationId": "req_789",
  },
  "to": "<FCM_TOKEN>"
}
```

---

> **Done!** Backend chỉ cần tuân theo bảng trên, client sẽ điều hướng chính xác ✨ 