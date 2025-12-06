import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Filter, X } from 'lucide-react';

interface FilterBarProps {
  onSearch?: (query: string) => void;
  onFilter?: (filters: Record<string, any>) => void;
  filters?: Array<{
    name: string;
    label: string;
    options: Array<{ value: string; label: string }>;
  }>;
}

export function FilterBar({ onSearch, onFilter, filters }: FilterBarProps) {
  return (
    <div className="flex flex-col sm:flex-row gap-4">
      {onSearch && (
        <div className="flex-1">
          <Input
            placeholder="Search..."
            onChange={(e) => onSearch(e.target.value)}
          />
        </div>
      )}
      
      {filters && filters.map((filter) => (
        <Select key={filter.name} onValueChange={(value) => onFilter?.({ [filter.name]: value })}>
          <SelectTrigger className="w-[180px]">
            <SelectValue placeholder={filter.label} />
          </SelectTrigger>
          <SelectContent>
            {filter.options.map((option) => (
              <SelectItem key={option.value} value={option.value}>
                {option.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      ))}
      
      <Button variant="outline" size="icon">
        <Filter className="h-4 w-4" />
      </Button>
    </div>
  );
}
