import { Metadata } from 'next'
import Link from 'next/link'
import { 
  Mail, 
  Github, 
  Twitter, 
  Linkedin, 
  MapPin, 
  Calendar,
  Code,
  Coffee,
  Heart,
  Award,
  BookOpen,
  Users
} from 'lucide-react'

export const metadata: Metadata = {
  title: '关于我 - 个人博客',
  description: '了解更多关于我的信息，我的技能、经历和兴趣爱好',
}

const skills = [
  { name: 'JavaScript', level: 95, color: '#F7DF1E' },
  { name: 'TypeScript', level: 90, color: '#3178C6' },
  { name: 'React', level: 92, color: '#61DAFB' },
  { name: 'Next.js', level: 88, color: '#000000' },
  { name: 'Node.js', level: 85, color: '#339933' },
  { name: 'Python', level: 80, color: '#3776AB' },
  { name: 'Vue.js', level: 75, color: '#4FC08D' },
  { name: 'Docker', level: 70, color: '#2496ED' },
]

const experiences = [
  {
    title: '高级前端工程师',
    company: '科技公司',
    period: '2022 - 至今',
    description: '负责大型 Web 应用的架构设计和开发，带领团队完成多个重要项目。',
    achievements: [
      '主导开发了公司核心产品的前端架构',
      '优化应用性能，页面加载速度提升 40%',
      '建立了完善的前端开发规范和工具链'
    ]
  },
  {
    title: '前端工程师',
    company: '互联网公司',
    period: '2020 - 2022',
    description: '参与多个产品的前端开发，积累了丰富的项目经验。',
    achievements: [
      '独立完成 5+ 个中大型项目的前端开发',
      '参与技术选型和架构设计',
      '指导新人，提升团队整体技术水平'
    ]
  },
  {
    title: '初级前端工程师',
    company: '创业公司',
    period: '2019 - 2020',
    description: '开始职业生涯，快速学习和成长。',
    achievements: [
      '快速掌握现代前端技术栈',
      '参与产品从 0 到 1 的完整开发过程',
      '建立了良好的代码习惯和工程思维'
    ]
  }
]

const stats = [
  { label: '写作年限', value: '3+', icon: Calendar },
  { label: '发布文章', value: '50+', icon: BookOpen },
  { label: '代码行数', value: '100K+', icon: Code },
  { label: '咖啡杯数', value: '1000+', icon: Coffee },
]

export default function AboutPage() {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Hero Section */}
      <div className="bg-gradient-to-br from-primary-600 to-primary-800 text-white">
        <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-20">
          <div className="max-w-4xl mx-auto">
            <div className="flex flex-col lg:flex-row items-center gap-12">
              <div className="flex-1">
                <h1 className="text-4xl lg:text-6xl font-bold mb-6">
                  你好，我是 <span className="text-primary-200">张三</span>
                </h1>
                <p className="text-xl lg:text-2xl text-primary-100 mb-8 leading-relaxed">
                  一名热爱技术的全栈开发者，专注于创建优雅的用户体验和高质量的代码。
                  我相信技术可以让世界变得更美好。
                </p>
                <div className="flex flex-wrap gap-4">
                  <Link
                    href="mailto:hello@example.com"
                    className="inline-flex items-center px-6 py-3 bg-white text-primary-600 font-medium rounded-lg hover:bg-primary-50 transition-colors duration-200"
                  >
                    <Mail className="h-5 w-5 mr-2" />
                    联系我
                  </Link>
                  <Link
                    href="/articles"
                    className="inline-flex items-center px-6 py-3 border-2 border-white text-white font-medium rounded-lg hover:bg-white hover:text-primary-600 transition-colors duration-200"
                  >
                    <BookOpen className="h-5 w-5 mr-2" />
                    阅读文章
                  </Link>
                </div>
              </div>
              <div className="flex-shrink-0">
                <div className="w-64 h-64 bg-white/10 rounded-full flex items-center justify-center backdrop-blur-sm">
                  <div className="w-48 h-48 bg-primary-500 rounded-full flex items-center justify-center text-6xl font-bold">
                    张
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Stats */}
      <div className="bg-white border-b border-gray-200">
        <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-12">
          <div className="max-w-4xl mx-auto">
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-8">
              {stats.map((stat, index) => (
                <div key={index} className="text-center">
                  <div className="inline-flex items-center justify-center w-12 h-12 bg-primary-100 rounded-lg mb-4">
                    <stat.icon className="h-6 w-6 text-primary-600" />
                  </div>
                  <div className="text-3xl font-bold text-gray-900 mb-2">
                    {stat.value}
                  </div>
                  <div className="text-gray-600">{stat.label}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* About Content */}
      <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-16">
        <div className="max-w-4xl mx-auto">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-12">
            {/* Main Content */}
            <div className="lg:col-span-2 space-y-12">
              {/* About Me */}
              <section>
                <h2 className="text-3xl font-bold text-gray-900 mb-6">关于我</h2>
                <div className="prose prose-lg max-w-none text-gray-700">
                  <p>
                    我是一名充满激情的全栈开发者，拥有 5 年的软件开发经验。
                    我专注于使用现代技术栈创建高质量的 Web 应用程序，
                    包括 React、Next.js、Node.js 和 Python。
                  </p>
                  <p>
                    除了编程，我还热爱写作和分享知识。我相信通过分享经验和见解，
                    可以帮助更多的开发者成长，同时也能让自己不断学习和进步。
                  </p>
                  <p>
                    在工作之余，我喜欢阅读技术书籍、参与开源项目，
                    以及探索新的技术趋势。我也是一个咖啡爱好者，
                    经常在咖啡店里思考和编码。
                  </p>
                </div>
              </section>

              {/* Experience */}
              <section>
                <h2 className="text-3xl font-bold text-gray-900 mb-6">工作经历</h2>
                <div className="space-y-8">
                  {experiences.map((exp, index) => (
                    <div key={index} className="bg-white rounded-xl border border-gray-200 p-6">
                      <div className="flex items-start justify-between mb-4">
                        <div>
                          <h3 className="text-xl font-semibold text-gray-900">
                            {exp.title}
                          </h3>
                          <p className="text-primary-600 font-medium">
                            {exp.company}
                          </p>
                        </div>
                        <span className="text-sm text-gray-500 bg-gray-100 px-3 py-1 rounded-full">
                          {exp.period}
                        </span>
                      </div>
                      <p className="text-gray-700 mb-4">{exp.description}</p>
                      <ul className="space-y-2">
                        {exp.achievements.map((achievement, i) => (
                          <li key={i} className="flex items-start">
                            <Award className="h-4 w-4 text-primary-600 mt-1 mr-2 flex-shrink-0" />
                            <span className="text-gray-600">{achievement}</span>
                          </li>
                        ))}
                      </ul>
                    </div>
                  ))}
                </div>
              </section>
            </div>

            {/* Sidebar */}
            <div className="space-y-8">
              {/* Contact Info */}
              <div className="bg-white rounded-xl border border-gray-200 p-6">
                <h3 className="text-xl font-semibold text-gray-900 mb-4">联系方式</h3>
                <div className="space-y-4">
                  <div className="flex items-center">
                    <MapPin className="h-5 w-5 text-gray-400 mr-3" />
                    <span className="text-gray-700">北京，中国</span>
                  </div>
                  <Link
                    href="mailto:hello@example.com"
                    className="flex items-center text-primary-600 hover:text-primary-700 transition-colors duration-200"
                  >
                    <Mail className="h-5 w-5 mr-3" />
                    hello@example.com
                  </Link>
                </div>
              </div>

              {/* Social Links */}
              <div className="bg-white rounded-xl border border-gray-200 p-6">
                <h3 className="text-xl font-semibold text-gray-900 mb-4">社交媒体</h3>
                <div className="space-y-3">
                  <Link
                    href="https://github.com"
                    className="flex items-center text-gray-700 hover:text-primary-600 transition-colors duration-200"
                  >
                    <Github className="h-5 w-5 mr-3" />
                    GitHub
                  </Link>
                  <Link
                    href="https://twitter.com"
                    className="flex items-center text-gray-700 hover:text-primary-600 transition-colors duration-200"
                  >
                    <Twitter className="h-5 w-5 mr-3" />
                    Twitter
                  </Link>
                  <Link
                    href="https://linkedin.com"
                    className="flex items-center text-gray-700 hover:text-primary-600 transition-colors duration-200"
                  >
                    <Linkedin className="h-5 w-5 mr-3" />
                    LinkedIn
                  </Link>
                </div>
              </div>

              {/* Skills */}
              <div className="bg-white rounded-xl border border-gray-200 p-6">
                <h3 className="text-xl font-semibold text-gray-900 mb-4">技能</h3>
                <div className="space-y-4">
                  {skills.map((skill, index) => (
                    <div key={index}>
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-sm font-medium text-gray-700">
                          {skill.name}
                        </span>
                        <span className="text-sm text-gray-500">
                          {skill.level}%
                        </span>
                      </div>
                      <div className="w-full bg-gray-200 rounded-full h-2">
                        <div
                          className="h-2 rounded-full transition-all duration-300"
                          style={{
                            width: `${skill.level}%`,
                            backgroundColor: skill.color,
                          }}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}