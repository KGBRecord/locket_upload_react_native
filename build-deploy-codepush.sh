#!/bin/bash

# Dừng script nếu gặp lỗi
set -e  

# Xử lý khi nhấn Ctrl + C
trap "echo -e '\n❌ Quá trình đã bị hủy!'; exit 1" SIGINT

# Yêu cầu nhập target version nếu chưa có
if [ -z "$TARGET_VERSION" ]; then
    read -p "🔹 Nhập phiên bản mục tiêu (dùng dấu phẩy hoặc dấu gạch ngang): " TARGET_VERSION
fi

# Yêu cầu nhập description nếu chưa có
echo "📝 Nhập mô tả phiên bản (nhấn Enter xuống dòng, Ctrl+D để kết thúc):"
DESCRIPTION=""
while IFS= read -r line; do
    DESCRIPTION+="$line"$'\n'
done


APP_NAME="locket_upload_react_native"
DEPLOYMENT="Production"

echo "🚀 Bắt đầu deploy CodePush..."
echo "📌 Phiên bản mục tiêu: $TARGET_VERSION"
echo "📝 Mô tả: $DESCRIPTION"

# Đẩy lên CodePush cho Android
echo "🚀 Deploy lên CodePush (Android)..."

code-push release-react "$APP_NAME" android \
  --deploymentName "$DEPLOYMENT" \
  --targetBinaryVersion "$TARGET_VERSION" \
  --mandatory \
  --description "$DESCRIPTION"

echo "✅ CodePush deploy hoàn tất!"

# Hỏi người dùng có muốn gửi thông báo qua FCM không
read -p "📢 Bạn có muốn gửi thông báo cập nhật qua FCM không? (y/n): " send_fcm
if [[ "$send_fcm" != "y" && "$send_fcm" != "Y" ]]; then
    echo "🚫 Bỏ qua gửi thông báo FCM."
    exit 0
fi

# Gửi thông báo qua Firebase Cloud Messaging (FCM)
echo "📢 Đang gửi thông báo cập nhật..."
PROJECT_ID=$(node -p "require('./google-services.json').project_info.project_id")
FCM_URL="https://fcm.googleapis.com/v1/projects/$PROJECT_ID/messages:send"
ACCESS_TOKEN=$(gcloud auth application-default print-access-token)

curl -X POST "$FCM_URL" \
     -H "Authorization: Bearer $ACCESS_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
          "message": {
            "android": {
              "restricted_package_name": "com.locket_upload"
            },
            "data": {
              "local_update": "true"
            },
            "notification": {
              "body": "'"$DESCRIPTION"'",
              "title": "Đã có bản cập nhật mới!"
            },
          "topic": "'"$TARGET_VERSION"'"
          }
        }'

echo "✅ Thông báo cập nhật đã được gửi!"
echo "🎉 Hoàn thành tất cả các bước thành công!"
