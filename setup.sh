#!/bin/bash

echo "🚀 PSG Placement Portal - Production Setup"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${RED}❌ .env file not found!${NC}"
    echo "Please create a .env file with all required environment variables."
    echo "Refer to DEPLOYMENT_GUIDE.md for details."
    exit 1
fi

echo -e "${GREEN}✅ Environment file found${NC}"
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
npm install

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to install dependencies${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Dependencies installed${NC}"
echo ""

# Generate Prisma Client
echo "🔧 Generating Prisma Client..."
npx prisma generate

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to generate Prisma Client${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prisma Client generated${NC}"
echo ""

# Run migrations
echo "🗄️  Running database migrations..."
npx prisma migrate deploy

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Database migration failed${NC}"
    echo -e "${YELLOW}ℹ️  If this is the first setup, try: npx prisma migrate dev${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Database migrated${NC}"
echo ""

# Optional: Seed database
read -p "Do you want to seed the database with initial data? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "🌱 Seeding database..."
    npm run prisma:seed
    
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}⚠️  Seeding failed or no seed script found${NC}"
    else
        echo -e "${GREEN}✅ Database seeded${NC}"
    fi
fi

echo ""
echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Run 'npm run dev' to start the development server"
echo "2. Visit http://localhost:3000"
echo "3. Create your first super admin user"
echo "4. Refer to DEPLOYMENT_GUIDE.md for deployment instructions"
echo ""
echo "For mobile development:"
echo "- Run 'npm run cap:sync' to sync with Capacitor"
echo "- Run 'npm run cap:android' to open Android Studio"
echo "- Run 'npm run cap:ios' to open Xcode"
echo ""
