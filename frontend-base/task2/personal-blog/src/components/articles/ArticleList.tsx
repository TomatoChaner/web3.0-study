import { Suspense } from 'react'
import Link from 'next/link'
import { Calendar, Clock, Eye, ArrowRight, ChevronLeft, ChevronRight } from 'lucide-react'
import { formatDate, formatReadingTime, cn } from '@/lib/utils'
import type { Article, PaginationParams } from '@/types'

interface ArticleListProps {
  page: number
  tag?: string
  search?: string
}

async function fetchArticles(page: number, tag?: string, search?: string) {
  const params = new URLSearchParams({
    page: page.toString(),
    limit: '10',
  })

  if (tag) params.set('tag', tag)
  if (search) params.set('search', search)

  const response = await fetch(`${process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000'}/api/articles?${params}`, {
    cache: 'no-store', // 确保获取最新数据
  })

  if (!response.ok) {
    throw new Error('Failed to fetch articles')
  }

  return response.json()
}

export async function ArticleList({ page, tag, search }: ArticleListProps) {
  try {
    const result = await fetchArticles(page, tag, search)
    
    if (!result.success) {
      throw new Error(result.error || 'Failed to fetch articles')
    }

    const articles: Article[] = result.data
    const pagination: PaginationParams = result.pagination

    if (articles.length === 0) {
      return (
        <div className="text-center py-12">
          <div className="text-gray-400 text-6xl mb-4">📝</div>
          <h3 className="text-xl font-semibold text-gray-900 mb-2">暂无文章</h3>
          <p className="text-gray-600 mb-6">
            {search || tag ? '没有找到符合条件的文章' : '还没有发布任何文章'}
          </p>
          {(search || tag) && (
            <Link
              href="/articles"
              className="inline-flex items-center px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors duration-200"
            >
              查看所有文章
            </Link>
          )}
        </div>
      )
    }

    return (
      <div className="space-y-8">
        {/* Articles */}
        <div className="space-y-6">
          {articles.map((article, index) => (
            <article
              key={article.id}
              className={cn(
                'group bg-white rounded-xl border border-gray-200 overflow-hidden transition-all duration-300 hover:shadow-lg hover:border-gray-300',
                index === 0 && 'lg:flex lg:items-center lg:space-x-8 lg:p-8'
              )}
            >
              {index === 0 ? (
                // Featured article layout
                <>
                  <div className="lg:flex-1 p-6 lg:p-0">
                    <div className="flex flex-wrap gap-2 mb-4">
                      {article.tags.slice(0, 3).map((tag) => (
                        <Link
                          key={tag.id}
                          href={`/articles?tag=${tag.slug}`}
                          className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium transition-colors duration-200"
                          style={{
                            backgroundColor: `${tag.color}20`,
                            color: tag.color,
                          }}
                        >
                          {tag.name}
                        </Link>
                      ))}
                    </div>

                    <h2 className="text-2xl lg:text-3xl font-bold text-gray-900 mb-4 group-hover:text-primary-600 transition-colors duration-200">
                      <Link href={`/articles/${article.slug}`}>
                        {article.title}
                      </Link>
                    </h2>

                    <p className="text-gray-600 text-lg mb-6 line-clamp-3">
                      {article.excerpt}
                    </p>

                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-6 text-sm text-gray-500">
                        <div className="flex items-center space-x-1">
                          <Calendar className="h-4 w-4" />
                          <span>{formatDate(article.created_at)}</span>
                        </div>
                        <div className="flex items-center space-x-1">
                          <Clock className="h-4 w-4" />
                          <span>{formatReadingTime(article.reading_time || 5)}</span>
                        </div>
                        <div className="flex items-center space-x-1">
                          <Eye className="h-4 w-4" />
                          <span>{article.views || 0} 次阅读</span>
                        </div>
                      </div>

                      <Link
                        href={`/articles/${article.slug}`}
                        className="flex items-center space-x-1 text-primary-600 hover:text-primary-700 font-medium group"
                      >
                        <span>阅读全文</span>
                        <ArrowRight className="h-4 w-4 group-hover:translate-x-1 transition-transform duration-200" />
                      </Link>
                    </div>
                  </div>

                  <div className="lg:w-80 lg:flex-shrink-0">
                    <div className="h-48 lg:h-64 bg-gradient-to-br from-primary-100 to-primary-200 flex items-center justify-center">
                      <div className="text-primary-600 text-4xl font-bold">
                        {article.title.charAt(0)}
                      </div>
                    </div>
                  </div>
                </>
              ) : (
                // Regular article layout
                <div className="p-6">
                  <div className="flex flex-wrap gap-2 mb-3">
                    {article.tags.slice(0, 2).map((tag) => (
                      <Link
                        key={tag.id}
                        href={`/articles?tag=${tag.slug}`}
                        className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium transition-colors duration-200"
                        style={{
                          backgroundColor: `${tag.color}20`,
                          color: tag.color,
                        }}
                      >
                        {tag.name}
                      </Link>
                    ))}
                  </div>

                  <h3 className="text-xl font-bold text-gray-900 mb-3 group-hover:text-primary-600 transition-colors duration-200">
                    <Link href={`/articles/${article.slug}`}>
                      {article.title}
                    </Link>
                  </h3>

                  <p className="text-gray-600 mb-4 line-clamp-2">
                    {article.excerpt}
                  </p>

                  <div className="flex items-center justify-between text-sm text-gray-500">
                    <div className="flex items-center space-x-4">
                      <div className="flex items-center space-x-1">
                        <Calendar className="h-4 w-4" />
                        <span>{formatDate(article.created_at)}</span>
                      </div>
                      <div className="flex items-center space-x-1">
                        <Clock className="h-4 w-4" />
                        <span>{formatReadingTime(article.reading_time || 5)}</span>
                      </div>
                    </div>

                    <Link
                      href={`/articles/${article.slug}`}
                      className="flex items-center space-x-1 text-primary-600 hover:text-primary-700 font-medium group"
                    >
                      <span>阅读</span>
                      <ArrowRight className="h-4 w-4 group-hover:translate-x-1 transition-transform duration-200" />
                    </Link>
                  </div>
                </div>
              )}
            </article>
          ))}
        </div>

        {/* Pagination */}
        {pagination.totalPages > 1 && (
          <div className="flex items-center justify-center space-x-2">
            {pagination.hasPrevPage && (
              <Link
                href={`/articles?page=${pagination.page - 1}${tag ? `&tag=${tag}` : ''}${search ? `&search=${search}` : ''}`}
                className="flex items-center px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 hover:text-gray-700 transition-colors duration-200"
              >
                <ChevronLeft className="h-4 w-4 mr-1" />
                上一页
              </Link>
            )}

            <div className="flex items-center space-x-1">
              {Array.from({ length: Math.min(5, pagination.totalPages) }, (_, i) => {
                const pageNum = i + 1
                const isActive = pageNum === pagination.page
                
                return (
                  <Link
                    key={pageNum}
                    href={`/articles?page=${pageNum}${tag ? `&tag=${tag}` : ''}${search ? `&search=${search}` : ''}`}
                    className={cn(
                      'px-3 py-2 text-sm font-medium rounded-lg transition-colors duration-200',
                      isActive
                        ? 'bg-primary-600 text-white'
                        : 'text-gray-500 bg-white border border-gray-300 hover:bg-gray-50 hover:text-gray-700'
                    )}
                  >
                    {pageNum}
                  </Link>
                )
              })}
            </div>

            {pagination.hasNextPage && (
              <Link
                href={`/articles?page=${pagination.page + 1}${tag ? `&tag=${tag}` : ''}${search ? `&search=${search}` : ''}`}
                className="flex items-center px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 hover:text-gray-700 transition-colors duration-200"
              >
                下一页
                <ChevronRight className="h-4 w-4 ml-1" />
              </Link>
            )}
          </div>
        )}
      </div>
    )
  } catch (error) {
    console.error('Error fetching articles:', error)
    return (
      <div className="text-center py-12">
        <div className="text-red-400 text-6xl mb-4">⚠️</div>
        <h3 className="text-xl font-semibold text-gray-900 mb-2">加载失败</h3>
        <p className="text-gray-600 mb-6">无法加载文章列表，请稍后重试</p>
        <button
          onClick={() => window.location.reload()}
          className="inline-flex items-center px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors duration-200"
        >
          重新加载
        </button>
      </div>
    )
  }
}