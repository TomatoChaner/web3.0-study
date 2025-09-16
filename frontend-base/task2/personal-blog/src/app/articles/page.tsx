import { Suspense } from 'react'
import { Metadata } from 'next'
import { ArticleList } from '@/components/articles/ArticleList'
import { ArticleFilters } from '@/components/articles/ArticleFilters'
import { LoadingSpinner } from '@/components/ui/LoadingSpinner'

export const metadata: Metadata = {
  title: '文章列表',
  description: '浏览所有技术文章，包含前端开发、全栈技术和最佳实践等内容',
}

interface ArticlesPageProps {
  searchParams: {
    page?: string
    tag?: string
    search?: string
  }
}

export default function ArticlesPage({ searchParams }: ArticlesPageProps) {
  const page = parseInt(searchParams.page || '1')
  const tag = searchParams.tag
  const search = searchParams.search

  return (
    <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-gray-900 mb-4">技术文章</h1>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            探索前端开发、全栈技术和软件工程的最新趋势与实践
          </p>
        </div>

        {/* Filters */}
        <div className="mb-8">
          <Suspense fallback={<div className="h-16 bg-gray-100 rounded-lg animate-pulse" />}>
            <ArticleFilters currentTag={tag} currentSearch={search} />
          </Suspense>
        </div>

        {/* Article List */}
        <Suspense fallback={<LoadingSpinner size="lg" className="py-12" />}>
          <ArticleList page={page} tag={tag} search={search} />
        </Suspense>
      </div>
    </div>
  )
}