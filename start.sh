#!/bin/bash

echo "Starting Hizmat AI on http://localhost:5001 ..."

osascript -e 'tell application "Terminal"
  do script "cd /Users/admin/Desktop/aihack/hizmat_ai/flutter_app && flutter run -d chrome --web-port 5001"
end tell'

echo "Done — Chrome will open automatically once Flutter finishes compiling."
