import { Metadata } from 'next'
import Link from 'next/link'
import { Hash, TrendingUp } from 'lucide-react'
import type { Tag } from '@/types'

export const metadata: Metadata = {
  title: '标签 - 个人博客',
  description: '浏览所有文章标签，发现感兴趣的内容',
}

async function fetchTags(): Promise<Tag[]> {
  try {
    const response = await fetch(
      `${process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000'}/api/tags?sort=popularity`,
      { cache: 'no-store' }
    )

    if (!response.ok) {
      throw new Error('Failed to fetch tags')
    }

    const result = await response.json()
    return result.success ? result.data : []
  } catch (error) {
    console.error('Error fetching tags:', error)
    return []
  }
}

export default async function TagsPage() {
  const tags = await fetchTags()

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200">
        <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-16">
          <div className="max-w-4xl mx-auto text-center">
            <div className="inline-flex items-center justify-center w-16 h-16 bg-primary-100 rounded-full mb-6">
              <Hash className="h-8 w-8 text-primary-600" />
            </div>
            <h1 className="text-4xl lg:text-5xl font-bold text-gray-900 mb-6">
              标签云
            </h1>
            <p className="text-xl text-gray-600 max-w-2xl mx-auto">
              探索不同主题的文章，找到你感兴趣的内容
            </p>
          </div>
        </div>
      </div>

      {/* Tags Grid */}
      <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="max-w-6xl mx-auto">
          {tags.length > 0 ? (
            <>
              {/* Popular Tags */}
              <div className="mb-12">
                <div className="flex items-center mb-6">
                  <TrendingUp className="h-6 w-6 text-primary-600 mr-2" />
                  <h2 className="text-2xl font-bold text-gray-900">热门标签</h2>
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                  {tags.slice(0, 8).map((tag) => (
                    <Link
                      key={tag.id}
                      href={`/articles?tag=${tag.slug}`}
                      className="group bg-white rounded-xl border border-gray-200 p-6 hover:shadow-lg hover:border-primary-300 transition-all duration-200"
                    >
                      <div className="flex items-center justify-between mb-4">
                        <div
                          className="w-12 h-12 rounded-lg flex items-center justify-center text-white font-bold text-lg"
                          style={{ backgroundColor: tag.color }}
                        >
                          #
                        </div>
                        <span className="text-sm text-gray-500 bg-gray-100 px-2 py-1 rounded-full">
                          {tag.article_count || 0} 篇
                        </span>
                      </div>
                      <h3 className="text-lg font-semibold text-gray-900 mb-2 group-hover:text-primary-600 transition-colors duration-200">
                        {tag.name}
                      </h3>
                      <p className="text-gray-600 text-sm line-clamp-2">
                        {tag.description || '暂无描述'}
                      </p>
                    </Link>
                  ))}
                </div>
              </div>

              {/* All Tags */}
              {tags.length > 8 && (
                <div>
                  <h2 className="text-2xl font-bold text-gray-900 mb-6">所有标签</h2>
                  <div className="bg-white rounded-xl border border-gray-200 p-8">
                    <div className="flex flex-wrap gap-3">
                      {tags.slice(8).map((tag) => (
                        <Link
                          key={tag.id}
                          href={`/articles?tag=${tag.slug}`}
                          className="inline-flex items-center px-4 py-2 rounded-full text-sm font-medium transition-all duration-200 hover:scale-105"
                          style={{
                            backgroundColor: `${tag.color}15`,
                            color: tag.color,
                            border: `1px solid ${tag.color}30`,
                          }}
                        >
                          <Hash className="h-3 w-3 mr-1" />
                          {tag.name}
                          <span className="ml-2 text-xs opacity-75">
                            ({tag.article_count || 0})
                          </span>
                        </Link>
                      ))}
                    </div>
                  </div>
                </div>
              )}
            </>
          ) : (
            <div className="text-center py-16">
              <div className="inline-flex items-center justify-center w-16 h-16 bg-gray-100 rounded-full mb-6">
                <Hash className="h-8 w-8 text-gray-400" />
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-2">
                暂无标签
              </h3>
              <p className="text-gray-600 mb-8">
                还没有任何标签，快去发布一些文章吧！
              </p>
              <Link
                href="/articles"
                className="inline-flex items-center px-6 py-3 bg-primary-600 text-white font-medium rounded-lg hover:bg-primary-700 transition-colors duration-200"
              >
                浏览文章
              </Link>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}