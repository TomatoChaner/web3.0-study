import { NextRequest, NextResponse } from 'next/server'
import { createServiceSupabase } from '@/lib/supabase'
import type { Author } from '@/types'

// GET /api/authors - 获取作者列表
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const page = parseInt(searchParams.get('page') || '1')
    const limit = parseInt(searchParams.get('limit') || '10')
    const search = searchParams.get('search') || ''

    if (page < 1 || limit < 1 || limit > 100) {
      return NextResponse.json(
        { error: 'Invalid pagination parameters' },
        { status: 400 }
      )
    }

    const supabase = createServiceSupabase()

    // 分页
    const from = (page - 1) * limit
    const to = from + limit - 1

    // 构建查询
    let query = supabase
      .from('authors')
      .select('*', { count: 'exact' })
      .range(from, to)
      .order('created_at', { ascending: false })

    // 搜索过滤
    if (search) {
      query = query.or(`name.ilike.%${search}%,bio.ilike.%${search}%`)
    }

    const { data, error, count } = await query

    if (error) {
      console.error('Error fetching authors:', error)
      return NextResponse.json(
        { error: 'Failed to fetch authors' },
        { status: 500 }
      )
    }

    // 计算分页信息
    const totalPages = Math.ceil((count || 0) / limit)

    return NextResponse.json({
      success: true,
      data: data || [],
      pagination: {
        page,
        limit,
        total: count || 0,
        totalPages,
        hasNextPage: page < totalPages,
        hasPrevPage: page > 1
      }
    })
  } catch (error) {
    console.error('Error in authors API:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}

// POST /api/authors - 创建新作者
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { name, email, bio, avatar, website } = body

    // 验证必填字段
    if (!name || !email) {
      return NextResponse.json(
        { error: 'Name and email are required' },
        { status: 400 }
      )
    }

    // 验证邮箱格式
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!emailRegex.test(email)) {
      return NextResponse.json(
        { error: 'Invalid email format' },
        { status: 400 }
      )
    }

    const supabase = createServiceSupabase()

    // 检查邮箱是否已存在
    const { data: existingAuthor } = await supabase
      .from('authors')
      .select('id')
      .eq('email', email)
      .single()

    if (existingAuthor) {
      return NextResponse.json(
        { error: 'Author with this email already exists' },
        { status: 409 }
      )
    }

    // 创建作者
    const { data, error } = await supabase
      .from('authors')
      .insert({
        name,
        email,
        bio: bio || null,
        avatar: avatar || null,
        website: website || null
      })
      .select()
      .single()

    if (error) {
      console.error('Error creating author:', error)
      return NextResponse.json(
        { error: 'Failed to create author' },
        { status: 500 }
      )
    }

    return NextResponse.json({
      success: true,
      data,
      message: 'Author created successfully'
    }, { status: 201 })
  } catch (error) {
    console.error('Error in authors API:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}