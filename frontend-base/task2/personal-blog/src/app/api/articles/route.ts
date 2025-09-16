import { NextRequest, NextResponse } from 'next/server'
import { createServerSupabase } from '@/lib/supabase'
import type { Article, PaginationParams } from '@/types'

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const page = parseInt(searchParams.get('page') || '1')
    const limit = parseInt(searchParams.get('limit') || '10')
    const tag = searchParams.get('tag')
    const search = searchParams.get('search')
    const featured = searchParams.get('featured') === 'true'

    const supabase = await createServerSupabase()

    // 构建查询
    let query = supabase
      .from('articles')
      .select(`
        *,
        author:authors(*),
        tags:article_tags(
          tag:tags(*)
        )
      `)
      .eq('published', true)
      .order('created_at', { ascending: false })

    // 添加过滤条件
    if (featured) {
      query = query.eq('featured', true)
    }

    if (tag) {
      query = query.contains('tags', [{ tag: { slug: tag } }])
    }

    if (search) {
      query = query.or(`title.ilike.%${search}%,excerpt.ilike.%${search}%,content.ilike.%${search}%`)
    }

    // 分页
    const from = (page - 1) * limit
    const to = from + limit - 1

    const { data: articles, error, count } = await query
      .range(from, to)
      .limit(limit)

    if (error) {
      console.error('Error fetching articles:', error)
      return NextResponse.json(
        { error: 'Failed to fetch articles' },
        { status: 500 }
      )
    }

    // 格式化数据
    const formattedArticles: Article[] = articles?.map((article: any) => ({
      ...article,
      tags: article.tags?.map((t: any) => t.tag) || [],
    })) || []

    // 计算分页信息
    const totalPages = Math.ceil((count || 0) / limit)
    const hasNextPage = page < totalPages
    const hasPrevPage = page > 1

    const pagination: PaginationParams = {
      page,
      limit,
      total: count || 0,
      totalPages,
      hasNextPage,
      hasPrevPage,
    }

    return NextResponse.json({
      success: true,
      data: formattedArticles,
      pagination,
    })
  } catch (error) {
    console.error('API Error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}