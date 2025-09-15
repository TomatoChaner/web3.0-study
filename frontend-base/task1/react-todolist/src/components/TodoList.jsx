import React, { useState } from 'react';

function TodoList() {
  // 使用 useState Hook 管理状态
  const [todos, setTodos] = useState([]); // 存储待办事项的数组
  const [inputValue, setInputValue] = useState(''); // 存储输入框中的内容

  // 处理输入框内容变化
  const handleInputChange = (e) => {
    setInputValue(e.target.value);
  };

  // 处理添加按钮点击
  const handleAddTodo = () => {
    // 检查输入框内容不为空
    if (inputValue.trim() !== '') {
      // 添加新的待办事项到数组中
      setTodos([...todos, { id: Date.now(), text: inputValue.trim() }]);
      // 清空输入框
      setInputValue('');
    }
  };

  // 处理删除按钮点击
  const handleDeleteTodo = (id) => {
    // 从todos数组中移除指定id的待办事项
    setTodos(todos.filter(todo => todo.id !== id));
  };

  return (
    <div className="todo-list">
      <h2>待办事项</h2>
      
      {/* 输入框和添加按钮 */}
      <div className="todo-input">
        <input
          type="text"
          value={inputValue}
          onChange={handleInputChange}
          placeholder="请输入待办事项"
          className="todo-input-field"
        />
        <button
          onClick={handleAddTodo}
          className="todo-add-button"
        >
          添加
        </button>
      </div>
      
      {/* 待办事项列表 */}
      <div className="todo-list-container">
        {todos.length === 0 ? (
          <p className="empty-message">暂无待办事项</p>
        ) : (
          <ul className="todo-items">
            {todos.map(todo => (
              <li key={todo.id} className="todo-item">
                <span className="todo-text">{todo.text}</span>
                <button
                  onClick={() => handleDeleteTodo(todo.id)}
                  className="todo-delete-button"
                >
                  删除
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}

export default TodoList;