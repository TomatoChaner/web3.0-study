import { Suspense } from 'react'
import { HeroSection } from '@/components/home/HeroSection'
import { FeaturedArticles } from '@/components/home/FeaturedArticles'
import { PopularTags } from '@/components/home/PopularTags'
import { AboutSection } from '@/components/home/AboutSection'
import { LoadingSpinner } from '@/components/ui/LoadingSpinner'

export default function HomePage() {
  return (
    <div className="space-y-16 pb-16">
      {/* Hero Section */}
      <HeroSection />

      {/* Featured Articles */}
      <section className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-12">
          <h2 className="text-3xl font-bold text-gray-900 mb-4">精选文章</h2>
          <p className="text-gray-600 max-w-2xl mx-auto">
            探索最新的技术趋势，分享实用的开发经验和深度思考
          </p>
        </div>
        <Suspense fallback={<LoadingSpinner />}>
          <FeaturedArticles />
        </Suspense>
      </section>

      {/* Popular Tags */}
      <section className="bg-gray-50 py-16">
        <div className="container mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold text-gray-900 mb-4">热门标签</h2>
            <p className="text-gray-600 max-w-2xl mx-auto">
              按主题浏览文章，快速找到感兴趣的内容
            </p>
          </div>
          <Suspense fallback={<LoadingSpinner />}>
            <PopularTags />
          </Suspense>
        </div>
      </section>

      {/* About Section */}
      <section className="container mx-auto px-4 sm:px-6 lg:px-8">
        <AboutSection />
      </section>
    </div>
  )
}