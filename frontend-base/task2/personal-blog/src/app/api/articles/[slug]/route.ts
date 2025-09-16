import { NextRequest, NextResponse } from 'next/server'
import { createServerSupabase } from '@/lib/supabase'
import type { Article } from '@/types'

export async function GET(
  request: NextRequest,
  { params }: { params: { slug: string } }
) {
  try {
    const { slug } = params
    const supabase = await createServerSupabase()

    // 获取文章详情
    const { data: article, error } = await supabase
      .from('articles')
      .select(`
        *,
        author:authors(*),
        tags:article_tags(
          tag:tags(*)
        )
      `)
      .eq('slug', slug)
      .eq('published', true)
      .single()

    if (error || !article) {
      return NextResponse.json(
        { error: 'Article not found' },
        { status: 404 }
      )
    }

    // 格式化数据
    const formattedArticle: Article = {
      ...article,
      tags: article.tags?.map((t: any) => t.tag) || [],
    }

    // 增加阅读量
    await supabase
      .from('articles')
      .update({ views: (article.views || 0) + 1 })
      .eq('id', article.id)

    return NextResponse.json({
      success: true,
      data: formattedArticle,
    })
  } catch (error) {
    console.error('API Error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}