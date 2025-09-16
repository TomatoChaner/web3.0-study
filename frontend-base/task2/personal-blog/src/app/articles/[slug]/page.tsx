import { Metadata } from 'next'
import { notFound } from 'next/navigation'
import Link from 'next/link'
import { Calendar, Clock, Eye, ArrowLeft, Share2 } from 'lucide-react'
import { formatDate, formatReadingTime } from '@/lib/utils'
import CommentSection from '@/components/comments/CommentSection'
import type { Article } from '@/types'

interface ArticlePageProps {
  params: { slug: string }
}

async function fetchArticle(slug: string): Promise<Article | null> {
  try {
    const response = await fetch(
      `${process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000'}/api/articles/${slug}`,
      { cache: 'no-store' }
    )

    if (!response.ok) {
      return null
    }

    const result = await response.json()
    return result.success ? result.data : null
  } catch (error) {
    console.error('Error fetching article:', error)
    return null
  }
}

export async function generateMetadata({ params }: ArticlePageProps): Promise<Metadata> {
  const article = await fetchArticle(params.slug)

  if (!article) {
    return {
      title: '文章未找到',
    }
  }

  return {
    title: article.title,
    description: article.excerpt,
    keywords: article.tags.map(tag => tag.name),
    authors: [{ name: article.author?.name || '未知作者' }],
    openGraph: {
      title: article.title,
      description: article.excerpt,
      type: 'article',
      publishedTime: article.created_at,
      authors: [article.author?.name || '未知作者'],
      tags: article.tags.map(tag => tag.name),
    },
    twitter: {
      card: 'summary_large_image',
      title: article.title,
      description: article.excerpt,
    },
  }
}

export default async function ArticlePage({ params }: ArticlePageProps) {
  const article = await fetchArticle(params.slug)

  if (!article) {
    notFound()
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200">
        <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="max-w-4xl mx-auto">
            {/* Back Button */}
            <Link
              href="/articles"
              className="inline-flex items-center text-gray-600 hover:text-gray-900 mb-8 transition-colors duration-200"
            >
              <ArrowLeft className="h-4 w-4 mr-2" />
              返回文章列表
            </Link>

            {/* Tags */}
            <div className="flex flex-wrap gap-2 mb-6">
              {article.tags.map((tag) => (
                <Link
                  key={tag.id}
                  href={`/articles?tag=${tag.slug}`}
                  className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium transition-colors duration-200"
                  style={{
                    backgroundColor: `${tag.color}20`,
                    color: tag.color,
                  }}
                >
                  {tag.name}
                </Link>
              ))}
            </div>

            {/* Title */}
            <h1 className="text-4xl lg:text-5xl font-bold text-gray-900 mb-6 leading-tight">
              {article.title}
            </h1>

            {/* Excerpt */}
            <p className="text-xl text-gray-600 mb-8 leading-relaxed">
              {article.excerpt}
            </p>

            {/* Meta */}
            <div className="flex flex-wrap items-center justify-between gap-4">
              <div className="flex items-center space-x-6 text-gray-500">
                {article.author && (
                  <div className="flex items-center space-x-2">
                    <div className="w-8 h-8 bg-primary-600 rounded-full flex items-center justify-center text-white text-sm font-medium">
                      {article.author.name.charAt(0)}
                    </div>
                    <span className="font-medium">{article.author.name}</span>
                  </div>
                )}
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

              {/* Share Button */}
              <button className="flex items-center space-x-2 px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors duration-200">
                <Share2 className="h-4 w-4" />
                <span>分享</span>
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="max-w-4xl mx-auto">
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
            <div className="p-8 lg:p-12">
              <div 
                className="prose prose-lg max-w-none prose-headings:text-gray-900 prose-p:text-gray-700 prose-a:text-primary-600 prose-strong:text-gray-900 prose-code:text-primary-600 prose-code:bg-primary-50 prose-pre:bg-gray-900 prose-pre:text-gray-100"
                dangerouslySetInnerHTML={{ __html: article.content }}
              />
            </div>
          </div>

          {/* Author Info */}
          {article.author && (
            <div className="mt-12 bg-white rounded-xl shadow-sm border border-gray-200 p-8">
              <div className="flex items-start space-x-4">
                <div className="w-16 h-16 bg-primary-600 rounded-full flex items-center justify-center text-white text-xl font-bold flex-shrink-0">
                  {article.author.name.charAt(0)}
                </div>
                <div className="flex-1">
                  <h3 className="text-xl font-bold text-gray-900 mb-2">
                    关于作者：{article.author.name}
                  </h3>
                  <p className="text-gray-600 mb-4">
                    {article.author.bio || '这个作者很神秘，什么都没有留下...'}
                  </p>
                  <Link
                    href="/about"
                    className="inline-flex items-center text-primary-600 hover:text-primary-700 font-medium transition-colors duration-200"
                  >
                    了解更多
                  </Link>
                </div>
              </div>
            </div>
          )}

          {/* Comments */}
          <div className="mt-12">
            <CommentSection 
              articleId={article.id} 
              comments={article.comments || []} 
            />
          </div>

          {/* Related Articles */}
          <div className="mt-12">
            <h2 className="text-2xl font-bold text-gray-900 mb-6">相关文章</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* 这里可以添加相关文章的逻辑 */}
              <div className="bg-white rounded-lg border border-gray-200 p-6 text-center text-gray-500">
                暂无相关文章
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}