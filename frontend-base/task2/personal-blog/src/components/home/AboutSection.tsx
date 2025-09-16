import Link from 'next/link'
import { Github, Twitter, Linkedin, Mail, MapPin, Briefcase, GraduationCap } from 'lucide-react'

const skills = [
  'JavaScript', 'TypeScript', 'React', 'Next.js', 'Node.js', 'Python',
  'PostgreSQL', 'MongoDB', 'Docker', 'AWS', 'Git', 'Figma'
]

const socialLinks = [
  {
    name: 'GitHub',
    href: 'https://github.com/zhangsan',
    icon: Github,
    color: 'hover:text-gray-900',
  },
  {
    name: 'Twitter',
    href: 'https://twitter.com/zhangsan',
    icon: Twitter,
    color: 'hover:text-blue-500',
  },
  {
    name: 'LinkedIn',
    href: 'https://linkedin.com/in/zhangsan',
    icon: Linkedin,
    color: 'hover:text-blue-600',
  },
  {
    name: 'Email',
    href: 'mailto:zhangsan@example.com',
    icon: Mail,
    color: 'hover:text-red-500',
  },
]

export function AboutSection() {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
      {/* Content */}
      <div className="space-y-6">
        <div className="space-y-4">
          <h2 className="text-3xl font-bold text-gray-900">关于我</h2>
          <p className="text-lg text-gray-600 leading-relaxed">
            你好！我是张三，一名充满热情的全栈开发工程师。我专注于使用现代技术栈构建高质量的 Web 应用程序，
            并热衷于分享技术知识和最佳实践。
          </p>
          <p className="text-gray-600 leading-relaxed">
            在这个博客中，我会分享我在前端开发、后端架构、DevOps 以及软件工程方面的经验和见解。
            我相信通过分享知识，我们可以共同成长，构建更好的软件产品。
          </p>
        </div>

        {/* Info */}
        <div className="space-y-3">
          <div className="flex items-center space-x-3 text-gray-600">
            <MapPin className="h-5 w-5 text-primary-600" />
            <span>北京，中国</span>
          </div>
          <div className="flex items-center space-x-3 text-gray-600">
            <Briefcase className="h-5 w-5 text-primary-600" />
            <span>全栈开发工程师</span>
          </div>
          <div className="flex items-center space-x-3 text-gray-600">
            <GraduationCap className="h-5 w-5 text-primary-600" />
            <span>计算机科学学士</span>
          </div>
        </div>

        {/* Social Links */}
        <div className="flex space-x-4">
          {socialLinks.map((link) => {
            const Icon = link.icon
            return (
              <a
                key={link.name}
                href={link.href}
                target="_blank"
                rel="noopener noreferrer"
                className={`p-2 text-gray-400 transition-colors duration-200 ${link.color}`}
              >
                <Icon className="h-5 w-5" />
                <span className="sr-only">{link.name}</span>
              </a>
            )
          })}
        </div>

        {/* CTA */}
        <div className="pt-4">
          <Link
            href="/about"
            className="inline-flex items-center px-6 py-3 bg-primary-600 text-white font-medium rounded-lg hover:bg-primary-700 transition-colors duration-200"
          >
            了解更多
          </Link>
        </div>
      </div>

      {/* Skills & Avatar */}
      <div className="space-y-8">
        {/* Avatar */}
        <div className="flex justify-center lg:justify-start">
          <div className="relative">
            <div className="w-48 h-48 bg-gradient-to-br from-primary-400 to-primary-600 rounded-full flex items-center justify-center text-white text-6xl font-bold">
              张
            </div>
            <div className="absolute -bottom-2 -right-2 w-16 h-16 bg-green-500 rounded-full flex items-center justify-center text-white text-sm font-medium">
              在线
            </div>
          </div>
        </div>

        {/* Skills */}
        <div className="space-y-4">
          <h3 className="text-xl font-semibold text-gray-900">技能栈</h3>
          <div className="flex flex-wrap gap-2">
            {skills.map((skill) => (
              <span
                key={skill}
                className="px-3 py-1 bg-gray-100 text-gray-700 text-sm font-medium rounded-full hover:bg-primary-100 hover:text-primary-700 transition-colors duration-200"
              >
                {skill}
              </span>
            ))}
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-3 gap-4 pt-4">
          <div className="text-center">
            <div className="text-2xl font-bold text-primary-600">100+</div>
            <div className="text-sm text-gray-600">文章</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-primary-600">50K+</div>
            <div className="text-sm text-gray-600">阅读量</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-primary-600">3+</div>
            <div className="text-sm text-gray-600">年经验</div>
          </div>
        </div>
      </div>
    </div>
  )
}