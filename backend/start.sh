cd backend
cat > start.sh << 'EOF'
#!/bin/bash
sudo service mysql start
node server.js
EOF
chmod +x start.sh