import { NextRequest, NextResponse } from 'next/server'
import { createServerSupabase } from '@/lib/supabase'
import type { Tag } from '@/types'

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const popular = searchParams.get('popular') === 'true'
    const limit = parseInt(searchParams.get('limit') || '50')

    const supabase = await createServerSupabase()

    let query = supabase
      .from('tag_stats')
      .select('*')

    if (popular) {
      query = query.order('article_count', { ascending: false })
    } else {
      query = query.order('name', { ascending: true })
    }

    if (limit > 0) {
      query = query.limit(limit)
    }

    const { data: tags, error } = await query

    if (error) {
      console.error('Error fetching tags:', error)
      return NextResponse.json(
        { error: 'Failed to fetch tags' },
        { status: 500 }
      )
    }

    // 格式化数据
    const formattedTags: Tag[] = tags?.map((tag: any) => ({
      ...tag,
      article_count: tag.article_count || 0,
    })) || []

    return NextResponse.json({
      success: true,
      data: formattedTags,
    })
  } catch (error) {
    console.error('API Error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}