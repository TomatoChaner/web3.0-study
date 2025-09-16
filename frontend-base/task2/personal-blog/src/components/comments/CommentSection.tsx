'use client'

import { useState } from 'react'
import { MessageCircle, Send, Heart, Reply } from 'lucide-react'
import { formatDate } from '@/lib/utils'
import type { Comment } from '@/types'

interface CommentSectionProps {
  articleId: string
  comments?: Comment[]
}

export default function CommentSection({ articleId, comments = [] }: CommentSectionProps) {
  const [newComment, setNewComment] = useState('')
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [replyTo, setReplyTo] = useState<string | null>(null)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!newComment.trim()) return

    setIsSubmitting(true)
    try {
      // 这里应该调用 API 提交评论
      console.log('Submitting comment:', { articleId, content: newComment, replyTo })
      
      // 模拟 API 调用
      await new Promise(resolve => setTimeout(resolve, 1000))
      
      setNewComment('')
      setReplyTo(null)
    } catch (error) {
      console.error('Error submitting comment:', error)
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleReply = (commentId: string) => {
    setReplyTo(commentId)
  }

  return (
    <div className="bg-white rounded-xl border border-gray-200 p-8">
      <div className="flex items-center mb-8">
        <MessageCircle className="h-6 w-6 text-primary-600 mr-2" />
        <h3 className="text-2xl font-bold text-gray-900">
          评论 ({comments.length})
        </h3>
      </div>

      {/* Comment Form */}
      <form onSubmit={handleSubmit} className="mb-8">
        <div className="mb-4">
          <label htmlFor="comment" className="sr-only">
            写下你的评论
          </label>
          <textarea
            id="comment"
            rows={4}
            value={newComment}
            onChange={(e) => setNewComment(e.target.value)}
            placeholder={replyTo ? '写下你的回复...' : '写下你的评论...'}
            className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent resize-none"
          />
        </div>
        <div className="flex items-center justify-between">
          <div className="text-sm text-gray-500">
            {replyTo && (
              <span>
                回复评论 
                <button
                  type="button"
                  onClick={() => setReplyTo(null)}
                  className="text-primary-600 hover:text-primary-700 ml-1"
                >
                  取消
                </button>
              </span>
            )}
          </div>
          <button
            type="submit"
            disabled={!newComment.trim() || isSubmitting}
            className="inline-flex items-center px-6 py-2 bg-primary-600 text-white font-medium rounded-lg hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200"
          >
            {isSubmitting ? (
              <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2" />
            ) : (
              <Send className="h-4 w-4 mr-2" />
            )}
            {isSubmitting ? '发布中...' : '发布评论'}
          </button>
        </div>
      </form>

      {/* Comments List */}
      <div className="space-y-6">
        {comments.length > 0 ? (
          comments.map((comment) => (
            <CommentItem
              key={comment.id}
              comment={comment}
              onReply={handleReply}
            />
          ))
        ) : (
          <div className="text-center py-12">
            <MessageCircle className="h-12 w-12 text-gray-300 mx-auto mb-4" />
            <p className="text-gray-500 text-lg">还没有评论</p>
            <p className="text-gray-400">成为第一个评论的人吧！</p>
          </div>
        )}
      </div>
    </div>
  )
}

interface CommentItemProps {
  comment: Comment
  onReply: (commentId: string) => void
}

function CommentItem({ comment, onReply }: CommentItemProps) {
  const [liked, setLiked] = useState(false)

  return (
    <div className="border-b border-gray-100 pb-6 last:border-b-0">
      <div className="flex items-start space-x-4">
        {/* Avatar */}
        <div className="w-10 h-10 bg-primary-600 rounded-full flex items-center justify-center text-white font-medium flex-shrink-0">
          {comment.author_name?.charAt(0) || 'A'}
        </div>

        <div className="flex-1 min-w-0">
          {/* Header */}
          <div className="flex items-center space-x-2 mb-2">
            <h4 className="font-medium text-gray-900">
              {comment.author_name || '匿名用户'}
            </h4>
            <span className="text-sm text-gray-500">
              {formatDate(comment.created_at)}
            </span>
          </div>

          {/* Content */}
          <div className="text-gray-700 mb-3 whitespace-pre-wrap">
            {comment.content}
          </div>

          {/* Actions */}
          <div className="flex items-center space-x-4">
            <button
              onClick={() => setLiked(!liked)}
              className={`inline-flex items-center space-x-1 text-sm transition-colors duration-200 ${
                liked
                  ? 'text-red-600 hover:text-red-700'
                  : 'text-gray-500 hover:text-gray-700'
              }`}
            >
              <Heart className={`h-4 w-4 ${liked ? 'fill-current' : ''}`} />
              <span>{(comment.like_count || 0) + (liked ? 1 : 0)}</span>
            </button>
            <button
              onClick={() => onReply(comment.id)}
              className="inline-flex items-center space-x-1 text-sm text-gray-500 hover:text-gray-700 transition-colors duration-200"
            >
              <Reply className="h-4 w-4" />
              <span>回复</span>
            </button>
          </div>

          {/* Replies */}
          {comment.replies && comment.replies.length > 0 && (
            <div className="mt-4 space-y-4">
              {comment.replies.map((reply) => (
                <CommentItem
                  key={reply.id}
                  comment={reply}
                  onReply={onReply}
                />
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}