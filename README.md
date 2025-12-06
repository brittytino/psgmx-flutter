# PSG Placement Portal

A comprehensive placement management system for PSG College of Technology's MCA Department.

## Features

- 🎓 Student profile management with completion tracking
- 📁 Project and document management
- 💬 Real-time group chat with content moderation
- 🏆 LeetCode statistics tracking
- 📢 Announcements system
- 👥 Role-based access control (Students, Class Reps, Super Admins)
- 📱 Mobile app support via Capacitor
- 🤖 AI-powered content moderation
- 📊 Batch management and handover

## Tech Stack

- **Frontend**: Next.js 14, React, TypeScript, Tailwind CSS, Shadcn UI, Framer Motion
- **Backend**: Next.js API Routes, Prisma ORM
- **Database**: PostgreSQL (Neon)
- **Storage**: Cloudinary
- **Real-time**: Socket.io
- **AI**: OpenRouter API
- **Mobile**: Capacitor.js
- **Deployment**: Vercel

## Prerequisites

- Node.js 18+ and npm
- PostgreSQL database (Neon recommended)
- Cloudinary account
- OpenRouter API key

## Installation

1. **Clone the repository**
git clone <repository-url>
cd placement-portal

text

2. **Install dependencies**
npm install

text

3. **Set up environment variables**
cp .env.example .env.local

text

Edit `.env.local` with your credentials:
DATABASE_URL="your-neon-postgres-url"
JWT_SECRET="your-secret-key"
CLOUDINARY_CLOUD_NAME="your-cloud-name"
CLOUDINARY_API_KEY="your-api-key"
CLOUDINARY_API_SECRET="your-api-secret"
OPENROUTER_API_KEY="your-openrouter-key"
NEXT_PUBLIC_APP_URL="http://localhost:3000"
NEXT_PUBLIC_SOCKET_URL="http://localhost:3001"

text

4. **Set up database**
npx prisma generate
npx prisma migrate dev
npm run prisma:seed

text

5. **Run development server**
Terminal 1 - Next.js
npm run dev

Terminal 2 - Socket.io server
npm run socket:dev

text

6. **Access the application**
- Web: http://localhost:3000
- Socket: http://localhost:3001

## Default Credentials

**Super Admin:**
- Register Number: `ADMIN001`
- Password: `admin123`

**Class Rep:**
- Register Number: `2025MCA001`
- Password: `classrep123`

**Students:**
- Register Number: `2025MCA002` to `2025MCA010`
- Password: `student123`

## Mobile App Setup

1. **Build for mobile**
npm run build
npx cap add android
npx cap add ios

text

2. **Sync with Capacitor**
npx cap sync

text

3. **Open in native IDE**
Android
npx cap open android

iOS
npx cap open ios

text

## Deployment

### Vercel Deployment

1. **Install Vercel CLI**
npm i -g vercel

text

2. **Deploy**
vercel

text

3. **Set environment variables in Vercel dashboard**

### Database Migrations (Production)

npx prisma migrate deploy

text

## Project Structure

placement-portal/
├── prisma/ # Database schema and migrations
├── public/ # Static assets
├── src/
│ ├── app/ # Next.js app directory
│ ├── components/ # React components
│ ├── lib/ # Utilities and helpers
│ ├── types/ # TypeScript types
│ └── server/ # Server utilities
├── capacitor/ # Mobile app config
└── scripts/ # Build scripts

text

## API Routes

- `/api/auth/*` - Authentication
- `/api/students/*` - Student management
- `/api/projects/*` - Project CRUD
- `/api/documents/*` - Document upload/delete
- `/api/groups/*` - Group chat
- `/api/announcements/*` - Announcements
- `/api/leetcode/*` - LeetCode sync
- `/api/admin/*` - Admin operations

## Features Documentation

### Student Features
- Complete profile with academic details
- Upload resume and documents
- Add/edit/delete projects
- Join group chat
- View announcements

### Class Representative Features
- View all class students
- Send notifications to students
- Monitor profile completion

### Super Admin Features
- Bulk student upload via Excel
- Manage all groups and conversations
- Create announcements
- View LeetCode statistics
- Graduate batches and handover admin

## Scheduled Jobs

- **LeetCode Sync**: Runs every 24 hours
- **Motivation Quote**: Generated daily at 6 AM

## Security Features

- JWT-based authentication
- Role-based access control
- Rate limiting on API routes
- Content moderation using AI
- Server-side session validation
- Input validation with Zod

## Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## License

MIT License - See LICENSE file for details

## Support

For issues and queries, contact: admin@psgtech.ac.in