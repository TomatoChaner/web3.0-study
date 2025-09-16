import Link from 'next/link'
import { Github, Twitter, Linkedin, Mail, Heart } from 'lucide-react'

const socialLinks = [
  {
    name: 'GitHub',
    href: 'https://github.com/zhangsan',
    icon: Github,
  },
  {
    name: 'Twitter',
    href: 'https://twitter.com/zhangsan',
    icon: Twitter,
  },
  {
    name: 'LinkedIn',
    href: 'https://linkedin.com/in/zhangsan',
    icon: Linkedin,
  },
  {
    name: 'Email',
    href: 'mailto:zhangsan@example.com',
    icon: Mail,
  },
]

const footerLinks = {
  博客: [
    { name: '最新文章', href: '/articles' },
    { name: '热门标签', href: '/tags' },
    { name: 'RSS 订阅', href: '/rss.xml' },
  ],
  关于: [
    { name: '关于我', href: '/about' },
    { name: '联系方式', href: '/contact' },
    { name: '友情链接', href: '/links' },
  ],
  其他: [
    { name: '隐私政策', href: '/privacy' },
    { name: '使用条款', href: '/terms' },
    { name: '网站地图', href: '/sitemap.xml' },
  ],
}

export function Footer() {
  const currentYear = new Date().getFullYear()

  return (
    <footer className="bg-gray-900 text-gray-300">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
          {/* Brand */}
          <div className="lg:col-span-1">
            <Link href="/" className="flex items-center space-x-2 mb-4">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary-600 text-white font-bold">
                B
              </div>
              <span className="text-xl font-bold text-white">个人博客</span>
            </Link>
            <p className="text-gray-400 mb-6 max-w-sm">
              分享技术心得，记录成长历程。专注于前端开发、全栈技术和最佳实践。
            </p>
            <div className="flex space-x-4">
              {socialLinks.map((link) => {
                const Icon = link.icon
                return (
                  <a
                    key={link.name}
                    href={link.href}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-gray-400 hover:text-primary-400 transition-colors duration-200"
                  >
                    <Icon className="h-5 w-5" />
                    <span className="sr-only">{link.name}</span>
                  </a>
                )
              })}
            </div>
          </div>

          {/* Links */}
          {Object.entries(footerLinks).map(([category, links]) => (
            <div key={category}>
              <h3 className="text-white font-semibold mb-4">{category}</h3>
              <ul className="space-y-2">
                {links.map((link) => (
                  <li key={link.name}>
                    <Link
                      href={link.href}
                      className="text-gray-400 hover:text-primary-400 transition-colors duration-200"
                    >
                      {link.name}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        {/* Bottom */}
        <div className="border-t border-gray-800 mt-12 pt-8">
          <div className="flex flex-col md:flex-row justify-between items-center">
            <p className="text-gray-400 text-sm">
              © {currentYear} 个人博客. 保留所有权利.
            </p>
            <p className="text-gray-400 text-sm flex items-center mt-4 md:mt-0">
              使用
              <Heart className="h-4 w-4 text-red-500 mx-1" />
              和 Next.js 构建
            </p>
          </div>
        </div>
      </div>
    </footer>
  )
}