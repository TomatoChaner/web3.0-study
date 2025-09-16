'use client'

import { useState, useEffect } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { Search, X, Tag as TagIcon } from 'lucide-react'
import { cn } from '@/lib/utils'
import type { Tag } from '@/types'

interface ArticleFiltersProps {
  currentTag?: string
  currentSearch?: string
}

export function ArticleFilters({ currentTag, currentSearch }: ArticleFiltersProps) {
  const router = useRouter()
  const searchParams = useSearchParams()
  const [searchValue, setSearchValue] = useState(currentSearch || '')
  const [tags, setTags] = useState<Tag[]>([])
  const [isLoading, setIsLoading] = useState(true)

  // 获取标签列表
  useEffect(() => {
    async function fetchTags() {
      try {
        const response = await fetch('/api/tags?popular=true&limit=20')
        const result = await response.json()
        if (result.success) {
          setTags(result.data)
        }
      } catch (error) {
        console.error('Failed to fetch tags:', error)
      } finally {
        setIsLoading(false)
      }
    }

    fetchTags()
  }, [])

  // 处理搜索
  const handleSearch = (value: string) => {
    const params = new URLSearchParams(searchParams.toString())
    
    if (value.trim()) {
      params.set('search', value.trim())
    } else {
      params.delete('search')
    }
    
    params.delete('page') // 重置页码
    router.push(`/articles?${params.toString()}`)
  }

  // 处理标签过滤
  const handleTagFilter = (tagSlug: string) => {
    const params = new URLSearchParams(searchParams.toString())
    
    if (currentTag === tagSlug) {
      params.delete('tag')
    } else {
      params.set('tag', tagSlug)
    }
    
    params.delete('page') // 重置页码
    router.push(`/articles?${params.toString()}`)
  }

  // 清除所有过滤器
  const clearFilters = () => {
    setSearchValue('')
    router.push('/articles')
  }

  const hasActiveFilters = currentTag || currentSearch

  return (
    <div className="space-y-6">
      {/* Search */}
      <div className="relative">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
          <input
            type="text"
            placeholder="搜索文章..."
            value={searchValue}
            onChange={(e) => setSearchValue(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                handleSearch(searchValue)
              }
            }}
            className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
          />
        </div>
        {searchValue && (
          <button
            onClick={() => handleSearch(searchValue)}
            className="absolute right-2 top-1/2 transform -translate-y-1/2 px-4 py-1 bg-primary-600 text-white text-sm rounded-md hover:bg-primary-700 transition-colors duration-200"
          >
            搜索
          </button>
        )}
      </div>

      {/* Tags */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-semibold text-gray-900 flex items-center">
            <TagIcon className="h-5 w-5 mr-2" />
            按标签筛选
          </h3>
          {hasActiveFilters && (
            <button
              onClick={clearFilters}
              className="flex items-center space-x-1 text-sm text-gray-500 hover:text-gray-700 transition-colors duration-200"
            >
              <X className="h-4 w-4" />
              <span>清除筛选</span>
            </button>
          )}
        </div>

        {isLoading ? (
          <div className="flex flex-wrap gap-2">
            {Array.from({ length: 8 }).map((_, i) => (
              <div
                key={i}
                className="h-8 w-20 bg-gray-200 rounded-full animate-pulse"
              />
            ))}
          </div>
        ) : (
          <div className="flex flex-wrap gap-2">
            {tags.map((tag) => (
              <button
                key={tag.id}
                onClick={() => handleTagFilter(tag.slug)}
                className={cn(
                  'inline-flex items-center px-3 py-1.5 rounded-full text-sm font-medium transition-all duration-200 hover:scale-105',
                  currentTag === tag.slug
                    ? 'text-white shadow-md'
                    : 'text-gray-700 hover:shadow-sm',
                )}
                style={{
                  backgroundColor: currentTag === tag.slug 
                    ? tag.color 
                    : `${tag.color}15`,
                  borderColor: `${tag.color}30`,
                  border: '1px solid',
                }}
              >
                {tag.name}
                <span className="ml-1 text-xs opacity-75">
                  ({tag.article_count})
                </span>
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Active Filters */}
      {hasActiveFilters && (
        <div className="flex items-center space-x-2 text-sm text-gray-600">
          <span>当前筛选:</span>
          {currentSearch && (
            <span className="inline-flex items-center px-2 py-1 bg-blue-100 text-blue-800 rounded-md">
              搜索: "{currentSearch}"
            </span>
          )}
          {currentTag && (
            <span className="inline-flex items-center px-2 py-1 bg-green-100 text-green-800 rounded-md">
              标签: {tags.find(t => t.slug === currentTag)?.name || currentTag}
            </span>
          )}
        </div>
      )}
    </div>
  )
}